provider "libvirt" {
  uri   = "qemu+ssh://root@192.168.0.171/system"
}

resource "libvirt_pool" "nomad" {
  name = "nomad"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-nomad"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

locals {
  nomad_cluster_servers_expanded = {
    for i in range(0, var.nomad_cluster_size):i => format("%s%s%d", var.consul_datacenter, "-server-nomad-", i)
  }
}

resource "tls_private_key" "nomad_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "nomad_ca" {
  key_algorithm   = tls_private_key.nomad_ca.algorithm
  private_key_pem = tls_private_key.nomad_ca.private_key_pem

  subject {
    common_name  = "nomad.msk.local"
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

resource "tls_private_key" "nomad" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "random_string" "nomad_gossip_password" {
  length = 16
  special = true
}

module "bastion" {
  source = "./bastion"

  datacenter ="dc1"
  consul_cli_ca_cert_pem     = module.consul_cluster.consul_cli_ca_cert_pem
  nomad_cli_ca_cert_pem     = module.consul_cluster.consul_cli_ca_cert_pem
  consul_cli_private_key_pem = module.consul_cluster.consul_cli_private_key_pem
  nomad_cli_private_key_pem = module.consul_cluster.consul_cli_private_key_pem
  consul_cli_cert_pem        = module.consul_cluster.consul_cli_cert_pem
  nomad_cli_cert_pem        = module.consul_cluster.consul_cli_cert_pem
  consul_master_token        = module.consul_cluster.consul_master_token
}

module "consul_cluster" {
  source = "./consul"

  datacenter = "dc1"
}
