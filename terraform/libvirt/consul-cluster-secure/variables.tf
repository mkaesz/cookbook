variable "consul_cluster_size" {
  description = "The size of the consul cluster."
  default = 3
}

variable "consul_clients" {
  description = "The number of clients to be provisioned."
  default = 2
}

variable "consul_datacenter" {
  description = "The datacenter."
  default = "dc1"
}
