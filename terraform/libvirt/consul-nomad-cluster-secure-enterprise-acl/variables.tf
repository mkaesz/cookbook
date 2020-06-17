variable "consul_cluster_size" {
  description = "The size of the consul cluster."
  default = 3
}

variable "nomad_cluster_size" {
  description = "The size of the nomad cluster."
  default = 3
}

variable "datacenter" {
  description = "The datacenter."
  default = "dc1"
}
