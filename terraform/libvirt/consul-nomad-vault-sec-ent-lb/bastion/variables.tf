variable "datacenter" {
  description = "The datacenter."
  default = "dc1"
}

variable "os_image" {
  description = "The os image to be used for the VMs."
  default     = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

variable "vault_ca_cert_pem" {}

variable "vault_cli_private_key_pem" {}

variable "vault_cli_cert_pem" {}

variable "consul_ca_cert_pem" {}

variable "consul_cli_private_key_pem" {}

variable "consul_cli_cert_pem" {}

variable "consul_master_token" {}

variable "nomad_ca_cert_pem" {}

variable "nomad_cli_private_key_pem" {}

variable "nomad_cli_cert_pem" {}
