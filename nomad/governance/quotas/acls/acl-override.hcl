namespace "default" {
  policy = "write"
  capabilities = ["sentinel-override"]
}

namespace "dev" {
  policy = "write"
  capabilities = ["sentinel-override"]
}

namespace "qa" {
  policy = "write"
  capabilities = ["sentinel-override"]
}

agent {
  policy = "read"
}

node {
  policy = "read"
}

