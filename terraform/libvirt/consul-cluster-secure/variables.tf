variable "consul_cluster_size" {
  description = "The size of the consul cluster."
  default = 3
}

variable "consul_datacenter" {
  description = "The datacenter."
  default = "dc1"
}
