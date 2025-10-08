package terraform.state

s3_backend_missing_encryption(backend) if {
  backend.type == "s3"
  not backend.config.encrypt
}

s3_backend_missing_kms_key(backend) if {
  backend.type == "s3"
  not backend.config.kms_key_id
}

encrypt_violation(backend) := ["Terraform remote state S3 backend must enable encrypt=true"] if {
  s3_backend_missing_encryption(backend)
}

encrypt_violation(backend) := [] if {
  not s3_backend_missing_encryption(backend)
}

kms_violation(backend) := ["Terraform remote state S3 backend must configure kms_key_id"] if {
  s3_backend_missing_kms_key(backend)
}

kms_violation(backend) := [] if {
  not s3_backend_missing_kms_key(backend)
}

violations_for_backend(backend) := array.concat(encrypt_violation(backend), kms_violation(backend))

deny contains msg if {
  backend := input.backend
  msg := violations_for_backend(backend)[_]
}
