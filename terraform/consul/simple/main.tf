# Access a key in Consul

provider "consul" {
     address    = "dc1-server-consul-0.msk.local:8500"
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
  license = file("~/workspace/consul-license.hclic")
}

resource "consul_namespace" "production" {
  name        = "production"
  description = "Production namespace"

  meta = {
    foo = "bar"
  }
}
