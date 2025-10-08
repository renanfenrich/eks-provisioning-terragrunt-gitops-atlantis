package terraform.state

test_s3_backend_with_encryption_and_kms_passes if {
  backend := {
    "type": "s3",
    "config": {
      "bucket": "example-state",
      "encrypt": true,
      "kms_key_id": "arn:aws:kms:us-east-1:111122223333:key/example"
    }
  }
  violations_for_backend(backend) == []
  not s3_backend_missing_encryption(backend)
  not s3_backend_missing_kms_key(backend)
}

test_missing_encryption_fails if {
  backend := {
    "type": "s3",
    "config": {
      "bucket": "unencrypted-state",
      "kms_key_id": "arn:aws:kms:us-east-1:111122223333:key/example"
    }
  }
  violations_for_backend(backend) == ["Terraform remote state S3 backend must enable encrypt=true"]
  s3_backend_missing_encryption(backend)
  not s3_backend_missing_kms_key(backend)
}

test_missing_kms_key_fails if {
  backend := {
    "type": "s3",
    "config": {
      "bucket": "missing-kms",
      "encrypt": true
    }
  }
  violations_for_backend(backend) == ["Terraform remote state S3 backend must configure kms_key_id"]
  s3_backend_missing_kms_key(backend)
  not s3_backend_missing_encryption(backend)
}
