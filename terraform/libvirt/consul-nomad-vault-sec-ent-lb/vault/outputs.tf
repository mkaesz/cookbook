output "vault_ca_cert_pem" {
  value = tls_self_signed_cert.vault_ca.cert_pem
}

output "vault_cli_cert_pem" {
  value = tls_locally_signed_cert.vault_cli.cert_pem
}

output "vault_cli_private_key_pem" {
  value = tls_private_key.vault.private_key_pem
}
