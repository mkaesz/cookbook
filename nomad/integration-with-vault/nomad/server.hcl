# Set the Datacenter
datacenter = "instruqt"
data_dir = "/root/hashistack/nomad/server"

# Setup the bind address
bind_addr = "0.0.0.0"

# Enable the server
server {
    enabled = true
    bootstrap_expect = 1
}

# Consul
consul {
    address = "127.0.0.1:8500"
}

# Vault
vault {
    enabled = false
    address = "http://active.vault.service.consul:8200"
    task_token_ttl = "1h"
    create_from_role = "nomad-cluster"
    token = "<your nomad server token>"
}

