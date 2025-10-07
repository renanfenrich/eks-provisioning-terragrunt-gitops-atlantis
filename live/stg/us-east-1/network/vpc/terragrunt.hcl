include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/vpc/aws//.?version=6.4.0"
}

locals {
  env          = include.region.locals.env
  default_tags = include.region.locals.tags
  name         = "${local.env}-vpc"

  vpc_network = {
    cidr            = "10.30.0.0/16"
    azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
    public_subnets  = ["10.30.101.0/24", "10.30.102.0/24", "10.30.103.0/24"]
  }

  vpc_settings = {
    enable_nat_gateway             = true
    single_nat_gateway             = true
    enable_dns_hostnames           = true
    enable_dns_support             = true
    manage_default_security_group  = true
    default_security_group_egress  = []
    default_security_group_ingress = []
  }

  flow_logs = {
    enable_flow_log                    = true
    flow_log_cloudwatch_log_group_name = "/vpc/${local.name}"
    flow_log_max_aggregation_interval  = 60
    flow_log_traffic_type              = "ALL"
  }
}

inputs = merge(
  local.vpc_network,
  local.vpc_settings,
  local.flow_logs,
  {
    name = local.name
    tags = merge(local.default_tags, {
      Name         = local.name
      name         = local.name
      finops_scope = "network-staging"
    })
  }
)
