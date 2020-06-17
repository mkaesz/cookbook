output "consul_cli_ca_cert_pem" {
  value = tls_self_signed_cert.consul_ca.cert_pem
}

output "consul_cli_cert_pem" {
  value = tls_locally_signed_cert.consul_cli.cert_pem
}

output "consul_cli_private_key_pem" {
  value = tls_private_key.consul.private_key_pem
} 

output "consul_master_token" {
  value = random_uuid.consul_master_token.result
}
