{
  "datacenter": "${datacenter}",
  "ui": true,
  "log_level": "INFO",
  "node_name": "${node_name}",
  "encrypt": "${gossip_password}",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "retry_join": ${consul_cluster_nodes},
  "verify_incoming": true,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/opt/consul/config/consul-ca.pem",
  "cert_file": "/opt/consul/config/${node_name}.crt",
  "key_file": "/opt/consul/config/${node_name}.key",
  "auto_encrypt": {
    "tls": true
  }
}

