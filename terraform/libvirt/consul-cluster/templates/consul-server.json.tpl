{
  "server": true,
  "ui": true,
  "log_level": "INFO",
  "node_name": "${node_name}",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "bootstrap_expect": ${cluster_size},
  "retry_join": ${consul_cluster_nodes},
  "ports": {
    "grpc": 8502
  },
  "connect": {
    "enabled": true
  }
}

