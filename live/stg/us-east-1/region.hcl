include "env" {
  path   = find_in_parent_folders("_env.hcl")
  expose = true
}

locals {
  region      = include.env.locals.region
  env         = include.env.locals.env
  aws_account = include.env.locals.aws_account
  base_domain = include.env.locals.base_domain
  tags        = include.env.locals.tags
}

inputs = {
  region = local.region
}
