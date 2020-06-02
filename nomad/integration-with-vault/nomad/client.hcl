# Set the Datacenter
datacenter = "instruqt"
data_dir = "/root/hashistack/nomad/client"

# Setup the bind address
bind_addr = "0.0.0.0"

# Enable the client
client {
    enabled = true
    servers = ["hashistack-server"]
}

# Consul
consul {
    address = "127.0.0.1:8500"
}

# Vault
vault {
    enabled = true
    address = "http://active.vault.service.consul:8200"
}

