locals {
  root_config    = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl"))
  account_config = read_terragrunt_config("${get_terragrunt_dir()}/account.hcl")
  env            = local.account_config.locals.env
  region         = local.account_config.locals.region
  aws_account    = local.account_config.locals.aws_account
  base_domain    = local.account_config.locals.base_domain
  tags           = merge(local.root_config.inputs.default_tags, local.account_config.locals.tags)
}
