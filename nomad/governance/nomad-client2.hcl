# Setup data dir
data_dir = "/tmp/nomad/client2"

# Give the agent a unique name.
name = "client2"

# Enable the client
client {
  enabled = true
}

# Consul configuration
consul {
  address = "nomad-client-2:8500"
}

