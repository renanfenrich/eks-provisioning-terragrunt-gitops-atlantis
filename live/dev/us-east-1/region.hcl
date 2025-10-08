locals {
  env_config  = read_terragrunt_config(find_in_parent_folders("_env.hcl"))
  region      = local.env_config.locals.region
  env         = local.env_config.locals.env
  aws_account = local.env_config.locals.aws_account
  base_domain = local.env_config.locals.base_domain
  tags        = local.env_config.locals.tags
}

inputs = {
  region = local.region
}
