output "minio_ca_cert_pem" {
  value = tls_self_signed_cert.minio_ca.cert_pem
}

output "minio_cli_cert_pem" {
  value = tls_locally_signed_cert.minio_cli.cert_pem
}

output "minio_cli_private_key_pem" {
  value = tls_private_key.minio.private_key_pem
}

output "minio_server" {
  value = libvirt_domain.minio_server.name
}
