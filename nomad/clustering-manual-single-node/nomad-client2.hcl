# Setup data dir
data_dir = "/tmp/nomad/client2"

# Give the agent a unique name. Defaults to hostname
name = "client2"

# Enable the client
client {
    enabled = true
    servers = ["nomad-server"]
}

