# Setup data dir
data_dir = "/tmp/nomad/client1"

# Give the agent a unique name.
name = "client1"

# Enable the client
client {
  enabled = true

  host_volume "mysql" {
    path      = "/opt/mysql/data"
    read_only = false
  }
}

# Consul configuration
consul {
  address = "nomad-client-1:8500"
}

