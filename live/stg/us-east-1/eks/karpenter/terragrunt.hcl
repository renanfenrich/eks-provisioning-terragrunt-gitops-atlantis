include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

dependency "eks" {
  config_path                             = "../cluster"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    cluster_name      = "stg-eks"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/STG"
    cluster_endpoint  = "https://stg.eks.amazonaws.com"
  }
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/karpenter/aws//.?version=1.6.2"
}

locals {
  env          = include.region.locals.env
  default_tags = include.region.locals.tags
  name         = "${local.env}-karpenter"
}

inputs = {
  create                           = true
  cluster_name                     = dependency.eks.outputs.cluster_name
  irsa_oidc_provider_arn           = dependency.eks.outputs.oidc_provider_arn
  enable_spot_interruption_handler = true
  interruption_handling            = { enable_queue = true }
  create_instance_profile          = true
  node_iam_role_name               = "${local.env}-karpenter-node"
  node_iam_role_additional_policies = {
    "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
  create_controller        = true
  controller_iam_role_name = "${local.env}-karpenter-controller"
  cluster_endpoint         = dependency.eks.outputs.cluster_endpoint
  consolidation            = { enabled = true }
  drift                    = { enabled = true }
  tags                     = merge(local.default_tags, { Name = local.name })
}
