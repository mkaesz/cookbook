resource "consul_license" "license" {
  license = file("~/workspace/consul-license.hclic")
}

