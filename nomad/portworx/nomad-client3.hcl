# Setup data dir
data_dir = "/tmp/nomad/client3"

# Give the agent a unique name.
name = "client3"

# Enable the client
client {
  enabled = true
}

# Consul configuration
consul {
  address = "nomad-client-3:8500"
}

plugin "docker" {
  config {
    allow_privileged = true
  }
}
