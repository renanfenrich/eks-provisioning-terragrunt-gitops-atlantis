include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  env          = local.account_vars.env
  region       = local.account_vars.region
  aws_account  = local.account_vars.aws_account
  base_domain  = local.account_vars.base_domain
  tags         = merge(include.root.inputs.default_tags, local.account_vars.tags)
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket       = "<state_bucket_stg>"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    kms_key_id   = "<kms_key_arn_stg>"
    use_lockfile = true
  }
}

generate "aws_provider_env" {
  path      = "aws_env.auto.tfvars"
  if_exists = "overwrite"
  contents  = <<-EOF
    region       = "${local.region}"
    default_tags = ${jsonencode(local.tags)}
  EOF
}
