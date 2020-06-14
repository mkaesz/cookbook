{
  "datacenter": "dc1",
  "ui": true,
  "log_level": "INFO",
  "node_name": "${node_name}",
  "encrypt": "c2RZPClSI3JMRlFwK2khZQ==",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "retry_join": ["dc1-server-consul-0"],
  "verify_incoming": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/opt/consul/config/consul-ca.pem",
  "auto_encrypt": {
    "tls": true
  }
}

