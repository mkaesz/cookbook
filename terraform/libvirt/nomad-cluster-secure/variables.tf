variable "nomad_cluster_size" {
  description = "The size of the nomad cluster."
  default = 3
}

variable "nomad_workers" {
  description = "The number of Nomad workers."
  default = 3
}
