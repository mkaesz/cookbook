resource "tls_cert_request" "minio_cli" {
  key_algorithm   = tls_private_key.minio.algorithm  
  private_key_pem = tls_private_key.minio.private_key_pem

  dns_names = [
    "${var.datacenter}-bastion",
    "server.${var.datacenter}.minio",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.datacenter}-bastion"
    organization = "msk"
  }
}

resource "tls_locally_signed_cert" "minio_cli" {
  cert_request_pem = tls_cert_request.minio_cli.cert_request_pem

  ca_key_algorithm   = tls_private_key.minio_ca.algorithm
  ca_private_key_pem = tls_private_key.minio_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.minio_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
}
