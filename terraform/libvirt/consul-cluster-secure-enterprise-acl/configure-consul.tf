provider "consul" {
  address    = "dc1-server-consul-0.msk.local:8500"
  datacenter = var.consul_datacenter
}

resource "time_sleep" "wait_10_seconds" {
  depends_on = [libvirt_domain.consul_server]

  create_duration = "10s"
}

resource "consul_license" "license" {
  license = file("~/workspace/consul-license.hclic")
  depends_on = [
    time_sleep.wait_10_seconds,
  ]
}

