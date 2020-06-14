storage "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
}

cache {
  use_auto_auth_token = false
}

listener "tcp" {
    address = "0.0.0.0:8200"
    cluster_address = "${node_name}:8201"
    tls_disable = true
}

ui=true

api_addr="http://${node_name}:8200"
cluster_addr="https://${node_name}:8200"
