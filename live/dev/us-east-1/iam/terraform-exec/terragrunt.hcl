include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}

terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/iam/aws//modules/iam-role?version=6.2.1"
}

locals {
  env          = include.region.locals.env
  aws_account  = include.region.locals.aws_account
  default_tags = include.region.locals.tags
  name         = "terraform-exec-${local.env}"
  assume_role_principals = [
    "arn:aws:iam::${local.aws_account}:role/${local.env}-atlantis-irsa"
  ]
}

inputs = {
  name = "${local.name}"
  assume_role_policy_statements = [{
    sid     = "AllowOrgPrincipals"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals = [{
      type        = "AWS"
      identifiers = local.assume_role_principals
    }]
  }]

  policy_statements = [
    {
      sid    = "TerraformProvisioning"
      effect = "Allow"
      actions = [
        "ec2:*",
        "eks:*",
        "iam:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "logs:*",
        "cloudwatch:*",
        "events:*",
        "route53:*",
        "kms:DescribeKey", "kms:List*", "kms:Encrypt", "kms:Decrypt", "kms:CreateGrant",
        "s3:*",
        "dynamodb:*"
      ]
      resources = ["*"]
    }
  ]

  max_session_duration = 14400
  tags                 = merge(local.default_tags, { Name = "${local.name}" })
}
