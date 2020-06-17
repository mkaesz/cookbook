datacenter= "${datacenter}"
bind_addr="${node_name}"
disable_update_check = true
enable_syslog = true
log_level = "INFO"
log_file = "/opt/nomad/data"
name = "${node_name}"
region = "europe"

server {
  enabled = true
  bootstrap_expect = ${cluster_size}
  encrypt = "${gossip_password}"
}

consul {
  address = "127.0.0.1:8501"
  auto_advertise = true
  server_service_name = "${datacenter}-nomad"
  server_http_check_name = "Nomad Server HTTP Check"
  server_serf_check_name = "Nomad Server Serf Check"
  server_rpc_check_name = "Nomad Server RPC Check"
  server_auto_join = true
  ssl = true
  ca_file = "/opt/consul/config/consul-ca.pem"
  cert_file = "/opt/consul/config/${node_name}.crt"
  key_file  = "/opt/consul/config/${node_name}.key"
}
