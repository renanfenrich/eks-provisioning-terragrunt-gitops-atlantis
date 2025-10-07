locals {
  env         = "dev"
  aws_account = "<account_id_dev>"
  region      = "us-east-1"
  base_domain = "<domain_if_any>"
  tags = {
    environment         = local.env
    account             = local.aws_account
    lifecycle           = "dev"
    criticality         = "low"
    cost_center         = "platform-dev"
    business_unit       = "infrastructure"
    product             = "eks-foundation"
    application         = "shared-eks"
    service             = "kubernetes"
    project             = "shared-infra"
    customer            = "internal"
    revenue_model       = "internal"
    chargeback_owner    = "platform-team"
    finops_scope        = "dev-core"
    scheduled           = "business-hours"
    savings_plan_intent = "evaluate"
    rightsize_status    = "reviewed"
    reserved_instance   = "no"
    pagerduty_service   = "platform-oncall"
    slack_channel       = "#platform-dev-alerts"
    support_tier        = "in-house"
    observability       = "enabled"
    terraform_workspace = "dev"
    git_commit          = ""
    change_ticket       = ""
  }
}
