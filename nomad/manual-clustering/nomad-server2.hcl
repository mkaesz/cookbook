# Setup data dir
data_dir = "/tmp/nomad/server2"

# Give the agent a unique name.
name = "server2"

# Enable the server
server {
  enabled = true
  bootstrap_expect = 3
  server_join {
    retry_join = ["nomad-server-1"]
  }
}

