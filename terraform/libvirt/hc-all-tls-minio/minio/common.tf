resource "tls_private_key" "minio_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "minio_ca" {
  key_algorithm   = tls_private_key.minio_ca.algorithm
  private_key_pem = tls_private_key.minio_ca.private_key_pem

  subject {
    common_name  = "minio.${var.domain}"
    organization = "msk"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "tls_private_key" "minio" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}
