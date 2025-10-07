terraform_version_constraint = ">= 1.6.0"
terragrunt_version_constraint = ">= 0.58.0"

locals {
  org       = "<org>"
  common_tags = {
    owner               = local.org
    managed_by          = "terragrunt"
    environment         = ""
    repo                = "iac//live"
    cost_center         = "platform"
    business_unit       = "infrastructure"
    product             = "eks-foundation"
    application         = "shared-eks"
    service             = "kubernetes"
    project             = "shared-infra"
    customer            = "internal"
    revenue_model       = "internal"
    chargeback_owner    = local.org
    lifecycle           = ""
    criticality         = "low"
    scheduled           = "off"
    savings_plan_intent = "evaluate"
    rightsize_status    = "pending"
    reserved_instance   = "no"
    finops_scope        = "base"
    data_classification = "internal"
    compliance          = "none"
    security_owner      = local.org
    backup              = "standard"
    retention_policy    = "30d"
    terraform_module    = "terragrunt"
    terraform_workspace = "terragrunt"
    git_repo            = "iac//live"
    git_commit          = ""
    change_ticket       = ""
    observability       = "enabled"
    pagerduty_service   = "platform-oncall"
    slack_channel       = "#platform-alerts"
    support_tier        = "in-house"
  }
}

generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.6.0"
      required_providers {
        aws = { source = "hashicorp/aws", version = "~> 6.15" }
      }
    }
    provider "aws" {
      region = var.region
      default_tags { tags = var.default_tags }
    }
    variable "region" { type = string }
    variable "default_tags" { type = map(string) }
  EOF
}

inputs = {
  default_tags = local.common_tags
}
