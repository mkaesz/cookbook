{
  "datacenter": "dc1",
  "ui": true,
  "log_level": "INFO",
  "node_name": "${node_name}",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "retry_join": ["consul-node-0"]
}

