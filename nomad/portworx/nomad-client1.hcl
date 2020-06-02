# Setup data dir
data_dir = "/tmp/nomad/client1"

# Give the agent a unique name.
name = "client1"

# Enable the client
client {
  enabled = true
}

# Consul configuration
consul {
  address = "nomad-client-1:8500"
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}
