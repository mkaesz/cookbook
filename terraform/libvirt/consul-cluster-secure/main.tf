provider "libvirt" {
  uri   = "qemu+ssh://root@192.168.0.171/system"
}

resource "libvirt_pool" "consul" {
  name = "consul"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-consul"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

resource "libvirt_volume" "volume" {
  name           = "volume-consul-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.consul_cluster_size
}

locals {
  consul_cluster_nodes_expanded = {
    for i in range(0, var.consul_cluster_size):i => format("%s%s%d", var.consul_datacenter, "-server-consul-", i)
  }
}

resource "tls_private_key" "consul-ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "consul-ca" {
  key_algorithm   = tls_private_key.consul-ca.algorithm
  private_key_pem = tls_private_key.consul-ca.private_key_pem

  subject {
    common_name  = "consul.msk.local"
    organization = "mskmania"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "consul" {
  key_algorithm   = tls_private_key.consul.algorithm
  private_key_pem = tls_private_key.consul.private_key_pem

  dns_names = [
    "${var.consul_datacenter}-server-consul-${count.index}",
    "server.dc1.consul",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.consul_datacenter}-server-consul-${count.index}"
    organization = "mskmania"
  }

  count          = var.consul_cluster_size
}

resource "tls_locally_signed_cert" "consul" {
  cert_request_pem = tls_cert_request.consul[count.index].cert_request_pem

  ca_key_algorithm   = tls_private_key.consul-ca.algorithm
  ca_private_key_pem = tls_private_key.consul-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul-ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count          = var.consul_cluster_size
}


resource "random_string" "consul_gossip_password" {
  length = 16
  special = true
}

data "template_file" "consul_server_config" {
  template = "${file("${path.module}/templates/consul-server.json.tpl")}"
  vars = {
    node_name = "${var.consul_datacenter}-server-consul-${count.index}"
    cluster_size = var.consul_cluster_size
    consul_cluster_nodes = jsonencode(values(local.consul_cluster_nodes_expanded))
    gossip_password = base64encode(random_string.consul_gossip_password.result)
}
count = var.consul_cluster_size
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "${var.consul_datacenter}-server-consul-${count.index}"
    consul_server_config = base64encode(data.template_file.consul_server_config[count.index].rendered)
    ca_file = base64encode(tls_self_signed_cert.consul-ca.cert_pem)
    cert_file = base64encode(tls_locally_signed_cert.consul[count.index].cert_pem)
    key_file = base64encode(tls_private_key.consul.private_key_pem)
  }
  count	= var.consul_cluster_size
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-${count.index}.iso"
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.consul.name
  count          = var.consul_cluster_size
}

resource "libvirt_domain" "consul_server" {
  name = "${var.consul_datacenter}-server-consul-${count.index}"
  count = var.consul_cluster_size

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

   provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}

}

output "nodes" {
  value = libvirt_domain.consul_server.*.name
}

output "ips" {
  value = libvirt_domain.consul_server.*.network_interface.0.addresses
}
