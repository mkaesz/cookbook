provider "consul" {
  address    = "dc1-server-consul-0.msk.local:8500"
  datacenter = var.consul_datacenter
}

resource "consul_license" "license" {
  license = file("~/workspace/consul-license.hclic")

 # depends_on = [
 #   libvirt_domain.consul_server,
 # ]
}

