provider "libvirt" {
  uri                              = "qemu+ssh://root@192.168.0.171/system"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "libvirt_pool" "tfe" {
  name = "tfe"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-tfe"
}

resource "libvirt_volume" "volume" {
  name           = "volume-tfe"
  base_volume_id = libvirt_volume.os_image.id
}

resource "tls_private_key" "tfe_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "tfe_ca" {
  key_algorithm   = tls_private_key.tfe_ca.algorithm
  private_key_pem = tls_private_key.tfe_ca.private_key_pem

  subject {
    common_name  = "tfe.${var.domain}"
    organization = "msk"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "tls_private_key" "tfe" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "tfe_server" {
  key_algorithm   = tls_private_key.tfe.algorithm
  private_key_pem = tls_private_key.tfe.private_key_pem

  dns_names = [
    "${var.datacenter}-server-tfe",
    "${var.datacenter}-server-tfe.${var.domain}",
    "server.${var.datacenter}.tfe",
    "server.global.tfe",
  ]

  subject {
    common_name  = "${var.datacenter}-server-minio.${var.domain}"
    organization = "msk"
  }
}

resource "tls_locally_signed_cert" "tfe_server" {
  cert_request_pem   = tls_cert_request.tfe_server.cert_request_pem
  ca_key_algorithm   = tls_private_key.tfe_ca.algorithm
  ca_private_key_pem = tls_private_key.tfe_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.tfe_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

data "template_file" "tfe_admin_user_config" {
  template = "${file("${path.module}/templates/tfe-admin-user.json.tpl")}"
  vars = {
    admin_username = "admin"
    admin_email    = "blub@blub.com"
    admin_password = "asdasdasdasd"
  }
}

data "template_file" "tfe_settings" {
  template = "${file("${path.module}/templates/tfe-settings.json.tpl")}"
  vars = {
    hostname                = "${var.datacenter}-tfe.${var.domain}"
  }
}

data "template_file" "replicated_conf" {
  template = "${file("${path.module}/templates/replicated.conf.tpl")}"
  vars = {
    hostname                = "${var.datacenter}-tfe.${var.domain}"
    replicated_password     = "asdasdasdasd"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname                = "${var.datacenter}-tfe.${var.domain}"
    domain                  = var.domain
    tfe_admin_user_config   = data.template_file.tfe_admin_user_config.rendered
    tfe_settings            = data.template_file.tfe_settings.rendered
    replicated_conf         = data.template_file.replicated_conf.rendered
    tfe_cert_file           = base64encode(tls_locally_signed_cert.tfe_server.cert_pem)
    tfe_key_file            = base64encode(tls_private_key.tfe.private_key_pem)
    tfe_lic_file            = file("~/workspace/marc-steffen-kaesz---mkaeszhashicorpcom---emea-tam.rli")
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-tfe.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.tfe.name
}

resource "libvirt_domain" "tfe" {
  name      = "${var.datacenter}-tfe"
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  memory = "10000"
  vcpu = "8"
  qemu_agent = true

  disk {
    volume_id = libvirt_volume.volume.id
  }

  network_interface {
    network_name   = "br0"
    wait_for_lease = true 
  }

  xml {
    xslt = file("qemuagent.xsl")
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

   provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}  
   provisioner "remote-exec" {
inline = [
  "sudo /tmp/install airgap no-proxy private-address=${self.name}.${var.domain} public-address=${self.name}.${var.domain}",
  "while ! curl -ksfS --connect-timeout 5 https://${self.name}.${var.domain}/_health_check; do sleep 5; done",
  "replicated admin --tty=0 retrieve-iact > /opt/tfe/config/iact.txt",
  "curl --header 'Content-Type: application/json' --request POST --data @'/opt/tfe/config/tfe-admin-user.json' https://${self.name}.${var.domain}/admin/initial-admin-user?token=$(cat /opt/tfe/config/iact.txt)"
]
}

   connection {
      type = "ssh"
      user = "mkaesz"
      host = "dc1-tfe.msk.local"
      private_key = file("~/.ssh/id_rsa")
   }
}
