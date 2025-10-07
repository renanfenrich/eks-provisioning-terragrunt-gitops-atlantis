locals {
  env         = "stg"
  aws_account = "<account_id_stg>"
  region      = "us-east-1"
  base_domain = "<domain_if_any>"
  tags = {
    environment         = local.env
    account             = local.aws_account
    lifecycle           = "staging"
    criticality         = "medium"
    cost_center         = "platform-stg"
    business_unit       = "infrastructure"
    product             = "eks-foundation"
    application         = "shared-eks"
    service             = "kubernetes"
    project             = "shared-infra"
    customer            = "internal"
    revenue_model       = "internal"
    chargeback_owner    = "platform-team"
    finops_scope        = "stg-core"
    scheduled           = "business-hours"
    savings_plan_intent = "evaluate"
    rightsize_status    = "reviewed"
    reserved_instance   = "no"
    pagerduty_service   = "platform-oncall"
    slack_channel       = "#platform-stg-alerts"
    support_tier        = "in-house"
    observability       = "enabled"
    terraform_workspace = "stg"
    git_commit          = ""
    change_ticket       = ""
  }
}
