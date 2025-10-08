# Terragrunt Infrastructure for EKS (dev & stg)

Infrastructure as code for the development and staging EKS clusters. Modules are
orchestrated with Terragrunt, using remote state, reusable inputs, and AWS IRSA
integration.

## Placeholders to replace
- `<account_id_dev>` / `<account_id_stg>` — AWS account IDs for each env
- `<domain>` — base domain shared with the GitOps repo (e.g., example.com)
- `<route53_zone_id>` — Route53 hosted zone used for DNS‑01 validation
- `<karpenter_controller_role_arn>` — IAM role ARN created for the Karpenter
  controller
- `<external_secrets_role_arn>` — IAM role ARN used by External Secrets
- `<alb_controller_role_arn>` — IAM role ARN used by the AWS Load Balancer
  Controller

## Glossary
- **Terragrunt** — Wrapper for Terraform that manages remote state, DRY configs.
- **Stack** — A Terragrunt working directory (`terragrunt.hcl`) that maps to a
  Terraform module.
- **IRSA** — IAM Roles for Service Accounts; required for controllers deployed
  via GitOps.
- **Workspace** — The `live/dev` or `live/stg` environment folder containing
  region-specific stacks.
- **Atlantis** — Automates `terragrunt plan/apply` from pull requests.

## Instructions
### Prerequisites
1. Install Terraform, Terragrunt, kubectl, and the AWS CLI.
2. Configure AWS credentials for the target account (`aws sso login` or static
   keys).
3. Ensure the remote state backend bucket/dynamo table referenced in `_env.hcl`
   exist (bootstrap them manually if this is the first run).

### Bootstrap order (dev)
```bash
cd live/dev/us-east-1/network/vpc        && terragrunt apply --all
cd live/dev/us-east-1/eks/cluster        && terragrunt apply
cd live/dev/us-east-1/eks/karpenter      && terragrunt apply
cd live/dev/us-east-1/iam/atlantis       && terragrunt apply
cd live/dev/us-east-1/iam/terraform-exec && terragrunt apply
```

### Bootstrap order (stg)
```bash
cd live/stg/us-east-1/network/vpc        && terragrunt apply --all
cd live/stg/us-east-1/eks/cluster        && terragrunt apply
cd live/stg/us-east-1/eks/karpenter      && terragrunt apply
cd live/stg/us-east-1/iam/atlantis       && terragrunt apply
cd live/stg/us-east-1/iam/terraform-exec && terragrunt apply
```

### Validating deployments
1. Run `terragrunt plan --all` from the environment root (`live/dev/us-east-1`
   or `live/stg/us-east-1`) before applying to catch drifts.
2. After each apply, reconcile the GitOps repo (see `apps/README.md`) so Argo CD
   installs the controllers using the IAM roles you just created.
3. Verify Karpenter provisioners, External Secrets, and ALB ingress objects can
   assume their IRSA roles by checking AWS CloudWatch logs or `kubectl
   describe sa`.

## Directory structure
```
live/
  root.hcl                   # root configuration and provider defaults
  dev/                       # development environment
    account.hcl              # account ID, region, domain inputs
    _env.hcl                 # remote state + provider tagging
    us-east-1/
      region.hcl             # helpers for region-specific inputs
      network/vpc/           # VPC + networking primitives
      eks/cluster/           # EKS control plane + node groups
      eks/karpenter/         # IAM & CRDs for Karpenter
      iam/                   # IRSA roles (Atlantis, terraform-exec, etc.)
  stg/                       # staging environment (mirror of dev)
```

## Tips
- Keep `root.hcl` inputs in sync between dev and stg to avoid drift.
- Run `terragrunt hclfmt` before committing.
- When bumping module versions, update both environments and run plans in CI.
