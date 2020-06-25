resource "libvirt_pool" "minio" {
  name = "minio"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-minio"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "libvirt_volume" "volume_server" {
  name           = "volume-server-minio"
  base_volume_id = libvirt_volume.os_image.id
}

resource "tls_cert_request" "minio_server" {
  key_algorithm   = tls_private_key.minio.algorithm
  private_key_pem = tls_private_key.minio.private_key_pem

  dns_names = [
    "${var.datacenter}-server-minio",
    "${var.datacenter}-server-minio.${var.domain}",
    "server.${var.datacenter}.minio",
    "server.global.minio",
    "server.europe.minio",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.datacenter}-server-minio.${var.domain}"
    organization = "msk"
  }
}

resource "tls_locally_signed_cert" "minio_server" {
  cert_request_pem   = tls_cert_request.minio_server.cert_request_pem
  ca_key_algorithm   = tls_private_key.minio_ca.algorithm
  ca_private_key_pem = tls_private_key.minio_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.minio_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}

data "template_file" "minio_server_config" {
  template        = "${file("${path.module}/templates/minio-server.config.tpl")}"
  vars = {
    hostname     = "${var.datacenter}-server-minio.${var.domain}"
  }
}

data "template_file" "user_data_minio_server" {
  template           = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname         = "${var.datacenter}-server-minio.${var.domain}"
    domain           = var.domain
    minio_config     = base64encode(data.template_file.minio_server_config.rendered)
    minio_ca_file    = base64encode(tls_self_signed_cert.minio_ca.cert_pem)
    minio_cert_file  = base64encode(tls_locally_signed_cert.minio_server.cert_pem)
    minio_key_file   = base64encode(tls_private_key.minio.private_key_pem)
  }
}

data "template_file" "network_config_client" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit_minio_server" {
  name           = "commoninit-minio-server.iso"
  user_data      = data.template_file.user_data_minio_server.rendered
  network_config = data.template_file.network_config_client.rendered
  pool           = libvirt_pool.minio.name
}

resource "libvirt_domain" "minio_server" {
  name       = "${var.datacenter}-server-minio"
  cloudinit  = libvirt_cloudinit_disk.commoninit_minio_server.id

  disk {
    volume_id = libvirt_volume.volume_server.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'  > /dev/null 2>&1
EOT  
}

  provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name} > /dev/null 2>&1
EOT  
}
}
