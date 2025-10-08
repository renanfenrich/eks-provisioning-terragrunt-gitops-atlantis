locals {
  env_config  = read_terragrunt_config(find_in_parent_folders("_env.hcl"))
  region      = local.env_config.locals.region
  env         = local.env_config.locals.env
  aws_account = local.env_config.locals.aws_account
  base_domain = local.env_config.locals.base_domain
  tags        = local.env_config.locals.tags
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket       = "<state_bucket>"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    kms_key_id   = "<kms_key_arn>"
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

inputs = {
  region = local.region
}
