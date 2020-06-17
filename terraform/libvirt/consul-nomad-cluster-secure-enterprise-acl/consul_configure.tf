provider "consul" {
  address    = "dc1-server-consul-0.msk.local:8500"
  datacenter = var.consul_datacenter
  token      = random_uuid.consul_master_token.result
}

resource "time_sleep" "wait_10_seconds" {
  depends_on = [libvirt_domain.consul_server]

  create_duration = "20s"
}

resource "consul_license" "license" {
  license = file("~/workspace/consul-license.hclic")
  depends_on = [
    time_sleep.wait_10_seconds,
  ]
}

resource "consul_autopilot_config" "config" {
    cleanup_dead_servers      =  false
    last_contact_threshold    =  "1s"
    max_trailing_logs         =  500
  depends_on = [
    time_sleep.wait_10_seconds,
  ]
}

resource "consul_acl_policy" "agent_server_policy" {
  name        = "${var.consul_datacenter}-server-consul-${count.index}"
  datacenters = ["${var.consul_datacenter}"]
  rules       = <<-RULE
    node "${var.consul_datacenter}-server-consul-${count.index}" {
      policy = "write"
    }
    agent "${var.consul_datacenter}-server-consul-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.consul_cluster_size
  depends_on = [
    time_sleep.wait_10_seconds,
  ]
}

resource "consul_acl_policy" "nomad_server_agent_client_policy" {
  name        = "${var.consul_datacenter}-server-nomad-${count.index}"
  datacenters = ["${var.consul_datacenter}"]
  rules       = <<-RULE
    node "${var.consul_datacenter}-server-nomad-${count.index}" {
      policy = "write"
    }
    agent "${var.consul_datacenter}-server-nomad-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.nomad_cluster_size
  depends_on = [
    time_sleep.wait_10_seconds,
  ]
}
