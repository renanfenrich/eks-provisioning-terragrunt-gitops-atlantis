include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

dependency "eks" {
  config_path                             = "../../eks/cluster"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    cluster_name            = "stg-eks"
    cluster_oidc_issuer_url = "https://oidc.eks.us-east-1.amazonaws.com/id/STGOIDC"
    oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/STGOIDC"
  }
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/iam/aws//modules/iam-role?version=6.2.1"
}

locals {
  env          = include.region.locals.env
  default_tags = include.region.locals.tags
  aws_account  = include.region.locals.aws_account
  name         = "${local.env}-atlantis"
}

# Atlantis IRSA role for staging deployments. Limited to assume execution roles in the staging account.
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
        "${replace(dependency.eks.outputs.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:atlantis:atlantis"
        "${replace(dependency.eks.outputs.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
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
      sid     = "AssumeExecutionRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      resources = [
        "arn:aws:iam::${local.aws_account}:role/terraform-exec-*"
      ]
    }
  ]

  tags = merge(local.default_tags, { Name = "${local.name}-irsa" })
}
