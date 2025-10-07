include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

dependency "eks" {
  config_path                             = "../../eks/cluster"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    cluster_name            = "dev-eks"
    cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLEOIDC"
    oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLEOIDC"
  }
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/iam/aws//modules/iam-role?version=6.2.1"
}

locals {
  env          = include.region.locals.env
  default_tags = include.region.locals.tags
  name         = "${local.env}-atlantis"
  oidc_issuer  = dependency.eks.outputs.cluster_oidc_issuer_url
  oidc_host    = replace(local.oidc_issuer, "https://", "")
}

# This role is assumed by the Atlantis ServiceAccount via IRSA.
# It can in turn assume a narrower Terraform execution role if you prefer a 2-hop model.
inputs = {
  name = "${local.name}-irsa"
  assume_role_policy_statements = [{
    sid     = "AllowEKSIRSA"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals = [{
      type        = "Federated"
      identifiers = [dependency.eks.outputs.oidc_provider_arn]
    }]
    condition = {
      StringEquals = {
        "${local.oidc_host}:sub" = "system:serviceaccount:atlantis:atlantis"
        "${local.oidc_host}:aud" = "sts.amazonaws.com"
      }
    }
  }]

  policy_statements = [
    {
      sid    = "TerraformStateCommon"
      effect = "Allow"
      actions = [
        "s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload",
        "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:UpdateItem", "dynamodb:DescribeTable"
      ]
      resources = ["*"]
    },
    {
      sid       = "AssumeExecutionRole"
      effect    = "Allow"
      actions   = ["sts:AssumeRole"]
      resources = ["arn:aws:iam::*:role/terraform-exec-*"]
    }
  ]

  tags = merge(local.default_tags, { Name = "${local.name}-irsa" })
}
