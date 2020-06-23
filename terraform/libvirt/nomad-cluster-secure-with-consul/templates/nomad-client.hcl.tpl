datacenter = "dc1"

bind_addr = "0.0.0.0"

client {
    enabled = true
    servers = ["nomad-node-0"]
}

consul {
    address = "127.0.0.1:8500"
}

# Vault
#vault {
#    enabled = true
#    address = "http://active.vault.service.consul:8200"
#}
