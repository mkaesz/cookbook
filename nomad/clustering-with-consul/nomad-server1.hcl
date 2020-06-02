# Setup data dir
data_dir = "/tmp/nomad/server1"

# Give the agent a unique name.
name = "server1"

# Enable the server
server {
  enabled = true
  bootstrap_expect = 3
}
