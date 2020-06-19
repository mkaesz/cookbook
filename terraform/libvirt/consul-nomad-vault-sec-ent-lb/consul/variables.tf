variable "cluster_size" {
  description = "The size of the consul cluster."
  default = 3
}

variable "datacenter" {
  description = "The datacenter."
  default = "dc1"
}

variable "os_image" {
  description = "The os image to be used for the VMs."
  default     = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

variable "consul_server" {
  description = "The Consul server to use to connect to to configure it."
  default     = "dc1-server-consul-0.msk.local:8500"
}
