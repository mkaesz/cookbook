variable "cluster_size" {
  default = 3
}

variable "workers" {
  default = 2
}

variable "datacenter" {
  default = "dc1"
}

variable "os_image" {
  description = "The os image to be used for the VMs."
  default     = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

variable "consul_gossip_password" {}

variable "consul_master_token" {}

variable "consul_server" {
   description = "The Consul server to use to connect to to configure it."
   default     = "dc1-server-consul-0.msk.local:8500"
 }

variable "consul_cluster_servers" {}

variable "consul_ca_cert_pem" {}

variable "consul_private_key_algorithm" {}

variable "consul_private_key_pem" {}
