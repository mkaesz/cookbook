# Setup data dir
data_dir = "/tmp/nomad/client1"

# Give the agent a unique name. Defaults to hostname
name = "client1"

# Enable the client
client {
    enabled = true
    servers = ["nomad-server"]
}
