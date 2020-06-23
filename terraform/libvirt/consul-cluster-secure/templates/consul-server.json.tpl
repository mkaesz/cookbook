{
  "server": true,
  "datacenter": "${datacenter}",
  "ui": true,
  "encrypt": "${gossip_password}",
  "log_level": "INFO",
  "node_name": "${node_name}",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "bootstrap_expect": ${cluster_size},
  "retry_join": ${consul_cluster_nodes},
  "verify_incoming": true,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/opt/consul/config/consul-ca.pem",
  "cert_file": "/opt/consul/config/${node_name}.crt",
  "key_file": "/opt/consul/config/${node_name}.key",
  "auto_encrypt": {
    "allow_tls": true
  },
  "ports": {
    "grpc": 8502
  },
  "connect": {
    "enabled": true
  }
}

