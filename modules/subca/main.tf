resource "vault_mount" "pki_intermediate" {
    path = "pki/${var.tld}_${var.domain}_intermediate"
    type = "pki"
    default_lease_ttl_seconds = 3600
    max_lease_ttl_seconds = 86400
}

resource "vault_pki_secret_backend_intermediate_cert_request" "pki_intermediate" {
  depends_on = [ vault_mount.pki_intermediate ]
  backend = vault_mount.pki_intermediate.path
  type = "internal"
  common_name = "intermediate-ca.${var.domain}.${var.tld}"
  format = "pem"
  private_key_format = "der"
  key_type = "rsa"
  key_bits = 4096
  exclude_cn_from_sans = true
  organization = "${var.domain}.${var.tld}"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "pki_root_sign_intermediate" {
  depends_on = [
      vault_pki_secret_backend_intermediate_cert_request.pki_intermediate,
      ]
  backend = var.pki_root_path
  common_name = vault_pki_secret_backend_intermediate_cert_request.pki_intermediate.common_name
  csr = vault_pki_secret_backend_intermediate_cert_request.pki_intermediate.csr
  use_csr_values = true
  ttl = 157680000   
}

resource "vault_pki_secret_backend_intermediate_set_signed" "pki_root_sign_intermediate" { 
  backend = vault_mount.pki_intermediate.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.pki_root_sign_intermediate.certificate
}