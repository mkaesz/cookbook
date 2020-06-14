datacenter= "dc1"
bind_addr="0.0.0.0"

server {
  enabled = true
  bootstrap_expect = ${cluster_size}
}

consul {
  address = "127.0.0.1:8500"
}
