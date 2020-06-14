# Access a key in Consul

provider "consul" {
     address    = "192.168.122.49:8500"
     #address    = "dc1-consul-server-0:8500"
     datacenter ="dc1" 
     scheme = "http"
   }

resource "consul_keys" "app" {
  key {
    path    = "cc"
    value = "ami-1234"
  }
}

resource "consul_license" "license" {
  license = file("license.hclic")
}

resource "consul_namespace" "production" {
  name        = "production"
  description = "Production namespace"

  meta = {
    foo = "bar"
  }
}
