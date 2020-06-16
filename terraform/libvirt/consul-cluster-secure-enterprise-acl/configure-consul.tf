resource "consul_license" "license" {
  license = file("~/workspace/consul-license.hclic")

 # depends_on = [
 #   libvirt_domain.consul_server,
 # ]
}

