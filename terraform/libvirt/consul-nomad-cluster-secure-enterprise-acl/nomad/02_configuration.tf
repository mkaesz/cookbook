provider "consul" {
  address    = var.consul_server
  datacenter = var.datacenter
  token      = var.consul_master_token
}

resource "consul_acl_policy" "consul_client_policy" {
  name        = "${var.datacenter}-client-consul-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node "${var.datacenter}-client-consul-${count.index}" {
      policy = "write"
    }
    agent "${var.datacenter}-client-consul-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.cluster_size
}

resource "consul_acl_policy" "nomad_server_policy" {
  name        = "${var.datacenter}-server-nomad-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node "${var.datacenter}-server-nomad-${count.index}" {
      policy = "write"
    }
    
    node "${var.datacenter}-server-nomad-${count.index}" {
      policy = "read"
    }
   
    service_prefix "" {
      policy = "write"
    }

    agent "${var.datacenter}-server-nomad-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.cluster_size
}
