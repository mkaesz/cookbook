provider "libvirt" {
  uri   = "qemu+ssh://root@192.168.0.171/system"
}

module "bastion" {
  source = "./bastion"

  datacenter = var.datacenter
  consul_ca_cert_pem         = module.consul_cluster.consul_ca_cert_pem
  nomad_ca_cert_pem          = module.nomad_cluster.nomad_ca_cert_pem
  consul_cli_private_key_pem = module.consul_cluster.consul_cli_private_key_pem
  nomad_cli_private_key_pem  = module.nomad_cluster.nomad_cli_private_key_pem
  consul_cli_cert_pem        = module.consul_cluster.consul_cli_cert_pem
  nomad_cli_cert_pem         = module.nomad_cluster.nomad_cli_cert_pem
  consul_master_token        = module.consul_cluster.consul_master_token
}

module "consul_cluster" {
  source = "./consul"

  datacenter    = var.datacenter
}

module "nomad_cluster" {
  source = "./nomad"

  datacenter                       = var.datacenter
  consul_server                    = module.consul_cluster.consul_server_0
  consul_gossip_password           = module.consul_cluster.consul_gossip_password 
  consul_master_token              = module.consul_cluster.consul_master_token
  consul_cluster_servers           = module.consul_cluster.consul_cluster_servers
  consul_ca_cert_pem               = module.consul_cluster.consul_ca_cert_pem
  consul_private_key_pem           = module.consul_cluster.consul_private_key_pem 
  consul_private_key_algorithm     = module.consul_cluster.consul_private_key_algorithm
}
