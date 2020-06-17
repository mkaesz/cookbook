resource "libvirt_pool" "bastion" {
  name = "bastion"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-bastion"
}

resource "libvirt_volume" "volume_bastion" {
  name           = "volume-bastion"
  base_volume_id = libvirt_volume.os_image.id
}

resource "tls_cert_request" "bastion_consul" {
  key_algorithm   = tls_private_key.consul.algorithm
  private_key_pem = tls_private_key.consul.private_key_pem

  dns_names = [
    "${var.consul_datacenter}-bastion",
    "server.${var.consul_datacenter}.consul",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.consul_datacenter}-bastion"
    organization = "mskmania"
  }
}

resource "tls_locally_signed_cert" "bastion_consul" {
  cert_request_pem = tls_cert_request.bastion_consul.cert_request_pem

  ca_key_algorithm   = tls_private_key.consul_ca.algorithm
  ca_private_key_pem = tls_private_key.consul_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

resource "tls_cert_request" "bastion_nomad" {
  key_algorithm   = tls_private_key.nomad.algorithm
  private_key_pem = tls_private_key.nomad.private_key_pem

  dns_names = [
    "${var.consul_datacenter}-bastion",
    "server.${var.consul_datacenter}.nomad",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.consul_datacenter}-bastion"
    organization = "mskmania"
  }
}

resource "tls_locally_signed_cert" "bastion_nomad" {
  cert_request_pem = tls_cert_request.bastion_nomad.cert_request_pem

  ca_key_algorithm   = tls_private_key.nomad_ca.algorithm
  ca_private_key_pem = tls_private_key.nomad_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

data "template_file" "user_data_bastion" {
  template = "${file("${path.module}/templates/cloud_init.bastion.cfg.tpl")}"
  vars = {
    hostname = "${var.consul_datacenter}-bastion"
    consul_ca_file = base64encode(tls_self_signed_cert.consul_ca.cert_pem)
    nomad_ca_file = base64encode(tls_self_signed_cert.nomad_ca.cert_pem)
    consul_cert_file = base64encode(tls_locally_signed_cert.bastion_consul.cert_pem)
    nomad_cert_file = base64encode(tls_locally_signed_cert.bastion_nomad.cert_pem)
    consul_key_file = base64encode(tls_private_key.consul.private_key_pem)
    nomad_key_file = base64encode(tls_private_key.nomad.private_key_pem)
    consul_master_token = random_uuid.consul_master_token.result
  }
}

data "template_file" "network_config_bastion" {
  template = file("${path.module}/templates/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit_bastion" {
  name           = "commoninit-bastion.iso"
  user_data      = data.template_file.user_data_bastion.rendered
  network_config = data.template_file.network_config_bastion.rendered
  pool           = libvirt_pool.bastion.name
}

resource "libvirt_domain" "bastion" {
  name = "${var.consul_datacenter}-bastion"

  cloudinit = libvirt_cloudinit_disk.commoninit_bastion.id

  disk {
    volume_id = libvirt_volume.volume_bastion.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
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
}
output "bastion" {
  value = libvirt_domain.bastion.name
}

output "ip" {
  value = libvirt_domain.bastion.network_interface.0.addresses
}
