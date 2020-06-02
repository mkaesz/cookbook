# Setup data dir
data_dir = "/tmp/nomad/server1"

# Give the agent a unique name.
name = "server1"

# Enable the server
server {
  enabled = true
  bootstrap_expect = 1
}

# Consul configuration
consul {
  address = "nomad-server-1:8500"
}

# Enable ACLs
acl {
  enabled = true
}
