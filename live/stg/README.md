# Staging Environment

Terragrunt configuration for the staging EKS footprint. Mirrors the dev layout
but uses production-like account guardrails, IAM policies, and chart versions.

## Placeholders to replace
- `<account_id_stg>` — AWS account ID for staging
- `<domain>` — base domain shared with the GitOps repo (e.g., example.com)
- `<route53_zone_id>` — Route53 hosted zone ID for certificate issuance
- `<alb_controller_role_arn>` / `<external_secrets_role_arn>` /
  `<karpenter_controller_role_arn>` — IAM role ARNs provisioned by Terragrunt

## Apply workflow
1. Authenticate to the staging AWS account.
2. From `live/stg/us-east-1/network/vpc`, run:
   ```bash
   terragrunt run-all plan
   terragrunt run-all apply
   ```
3. From `live/stg/us-east-1/eks/cluster`, run `terragrunt apply`.
4. From `live/stg/us-east-1/eks/karpenter`, run `terragrunt apply`.
5. From `live/stg/us-east-1/iam`, apply the IRSA roles (`atlantis`,
   `terraform-exec`, and any additional stacks).

## Post-apply checklist
- Trigger the Argo CD bootstrap (see `apps/README.md`) so controllers deploy
  using the new IAM roles.
- Confirm AWS Load Balancer Controller, External Secrets, and Karpenter pods use
  the staged IAM roles (`kubectl describe sa ...`).
- Run smoke tests against the sample service ingress once certificates provision.

## Atlantis integration
The staging runs use the `stg-eks` workflow defined in
`atlantis-example/atlantis.yaml`, which enforces plans before apply.
