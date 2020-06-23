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

locals {
  consul_cluster_servers_expanded = {
    for i in range(0, var.consul_cluster_size):i => format("%s%s%d", var.consul_datacenter, "-server-consul-", i)
  }
}

locals {
  consul_cluster_clients_expanded = {
    for i in range(0, var.consul_clients):i => format("%s%s%d", var.consul_datacenter, "-clients-consul-", i)
  }
}

resource "tls_private_key" "consul_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "consul_ca" {
  key_algorithm   = tls_private_key.consul_ca.algorithm
  private_key_pem = tls_private_key.consul_ca.private_key_pem

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

resource "random_string" "consul_gossip_password" {
  length = 16
  special = true
}

resource "random_uuid" "consul_master_token" { }

output "consul-ca" {
  value = tls_self_signed_cert.consul_ca.cert_pem
}
