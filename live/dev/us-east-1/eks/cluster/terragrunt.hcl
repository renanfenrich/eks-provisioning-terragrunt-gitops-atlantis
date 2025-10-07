include "region" {
  path   = find_in_parent_folders("region.hcl")
  expose = true
}
dependency "vpc" {
  config_path                             = "../../network/vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id          = "vpc-000000"
    private_subnets = ["subnet-111", "subnet-222", "subnet-333"]
  }
}
terraform {
  source = "tfr://registry.terraform.io/terraform-aws-modules/eks/aws//.?version=21.3.2"
}

locals {
  env          = include.region.locals.env
  default_tags = include.region.locals.tags
  name         = "${local.env}-eks"

  cluster_addons = {
    coredns    = { version = "v1.11.1-eksbuild.1" }
    kube-proxy = { version = "v1.30.3-eksbuild.1" }
    vpc-cni    = { version = "v1.18.3-eksbuild.1" }
  }

  managed_node_groups = {
    system = {
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.large"]
      desired_size   = 1
      min_size       = 1
      max_size       = 3
      labels         = { workload = "system" }
      taints         = [{ key = "system", value = "true", effect = "NoSchedule" }]
      disk_size      = 40
      tags = merge(local.default_tags, {
        Name                                  = "${local.name}-system"
        name                                  = "${local.name}-system"
        "kubernetes.io/cluster/${local.name}" = "owned"
        finops_scope                          = "system-core"
      })
    }
  }

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

inputs = {
  cluster_name              = local.name
  cluster_version           = "1.30"
  vpc_id                    = dependency.vpc.outputs.vpc_id
  subnet_ids                = dependency.vpc.outputs.private_subnets
  enable_irsa               = true
  cluster_addons            = local.cluster_addons
  eks_managed_node_groups   = local.managed_node_groups
  cluster_enabled_log_types = local.enabled_log_types
  tags                      = merge(local.default_tags, {
    Name = local.name
    name = local.name
  })
}
