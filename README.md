# EKS Provisioning with Terragrunt, GitOps & Atlantis

Infrastructure-as-code bundle for standing up Amazon EKS environments with
Terragrunt-managed Terraform, GitOps (Argo CD + Kustomize), and Atlantis-powered
automation. The repo ships two environments (`dev`, `stg`), reusable IAM/IRSA
roles, and a sample application to validate ingress, TLS, and secrets wiring end
to end.

## What’s inside
- `live/` — Terragrunt wrappers for shared VPC, EKS control plane, Karpenter,
  and IAM roles required by controllers and Atlantis.
- `apps/` — Argo CD bootstrap plus per-environment overlays for core add-ons
  (cert-manager, External Secrets, AWS Load Balancer Controller, Kyverno,
  Karpenter, ADOT, CSI drivers, etc.) and a sample workload.
- `atlantis-example/` — Reference `atlantis.yaml` workflows that run Terragrunt
  plans/applies in PRs.
- `.gitignore` — Optimized for Terraform/Terragrunt state, generated files, and
  common local artifacts.

## Prerequisites
- AWS accounts for `dev` and `stg`, with IAM permissions to provision VPC, EKS,
  IAM roles, Route 53, KMS, etc.
- Terraform ≥ 1.6, Terragrunt ≥ 0.58, kubectl, AWS CLI, and (optionally) the
  Argo CD CLI.
- Remote state S3 bucket(s); add DynamoDB table(s) if you plan to enable state
  locking.
- DNS zone in Route 53 if you plan to issue certificates via cert-manager.

## Replace placeholders
Update all `<...>` placeholders before running any plans. Key values include:

| Placeholder | Location | Description |
|-------------|----------|-------------|
| `<org>` | `live/terragrunt.hcl`, `apps/argo/bootstrap/*.yaml` | Git hosting org/user used by Argo CD |
| `<account_id_dev>`, `<account_id_stg>` | `live/*/account.hcl`, various manifests | AWS account IDs per environment |
| `<domain>` / `<domain_if_any>` | `live/*/account.hcl`, app manifests | Base DNS domain for ingress |
| `<route53_zone_id>` | cert-manager issuers | Route 53 hosted zone for DNS-01 challenges |
| `<state_bucket>` / `<state_bucket_stg>` | `_env.hcl` files | Remote state S3 bucket names |
| `<kms_key_arn>` / `<kms_key_arn_stg>` | `_env.hcl` files | KMS key ARN used to encrypt state |
| `<alb_controller_role_arn>`, `<external_secrets_role_arn>`, `<karpenter_controller_role_arn>` | Add-on service accounts | IRSA role ARNs created by Terraform |

Search for `<>` to catch any leftovers.

## Quick start
```bash
# 1. Clone & install tooling
git clone <repo-url>
cd eks-provisioning-terragrunt-gitops-atlantis

# 2. Fill placeholders (search for '<' and update)

# 3. (Optional) Format Terragrunt files
terragrunt hclfmt

# 4. Bootstrap dev
cd live/dev/us-east-1/network/vpc        && terragrunt run-all apply
cd ../eks/cluster                        && terragrunt apply
cd ../eks/karpenter                      && terragrunt apply
cd ../../iam/atlantis                    && terragrunt apply
cd ../terraform-exec                     && terragrunt apply

# 5. Repeat for staging
cd ../../../../stg/us-east-1/network/vpc && terragrunt run-all apply
# ...follow README instructions under live/stg/
```

After infrastructure is in place, point `kubectl` at the new cluster and apply
the Argo CD bootstrap manifests under `apps/argo/bootstrap/`. Argo CD will sync
the controller add-ons and the sample application automatically.

## GitOps workflow
1. Infra changes: update HCL under `live/`, run `terragrunt run-all plan`, and
   apply through Atlantis or the CLI.
2. Platform add-ons: edit Kustomize overlays in `apps/clusters/<env>` and let
   Argo CD reconcile the cluster.
3. Applications: add new Helm charts or manifests under `apps/services/`,
   reference them in the environment overlays, and let Git drive deployment.

## Atlantis integration
The `atlantis-example/atlantis.yaml` file registers the `dev` and `stg`
Terragrunt stacks and defines a reusable workflow that runs `terragrunt run-all
init/plan/apply`. Update repo allowlists, credentials, and any custom workflows
before deploying Atlantis (see `apps/clusters/*/addons/atlantis`).

## Repository structure
```
.
├── live/                    # Terragrunt environments (dev, stg)
├── apps/                    # Argo CD bootstrap & cluster add-ons
├── atlantis-example/        # Reference Atlantis config
└── README.md                # You are here
```

## Recommended checks
- `terragrunt hclfmt` — format configuration before committing.
- `terragrunt run-all plan` — run from the environment root to ensure a clean
  plan.
- `kubectl get applications.argoproj.io -n argocd` — verify Argo CD sync health.
- `aws sts get-caller-identity` — confirm AWS credentials target the expected
  account before applying.

## Continuous integration
GitHub Actions under `.github/workflows/terragrunt-validation.yml` install
Terragrunt via `gruntwork-io/terragrunt-action`, cache Terraform plugins and
modules, and fan out `terragrunt run-all init/validate/validate-inputs` across
each environment with the state backend disabled. Downstream jobs publish SARIF
results from `bridgecrewio/checkov-action@v12` scans and, when `policy/*.rego` is present, execute OPA
unit tests. Runs short-circuit when a newer commit arrives thanks to workflow
concurrency, and you can opt into OIDC-authenticated AWS plans by setting
`AWS_ROLE_TO_ASSUME` as an org/repo variable.

### Reusable deploy workflow
`.github/workflows/terragrunt-deploy.yml` exposes a reusable `workflow_call`
interface so other repos (or additional pipelines here) can run `terragrunt
run-all` commands without duplicating setup logic. Example usage:

```yaml
jobs:
  plan-dev:
    uses: ./.github/workflows/terragrunt-deploy.yml
    with:
      working_dir: live/dev
      command: plan
    secrets: inherit
```

Pass `secrets.aws_role_to_assume` (preferred, via GitHub OIDC) or static AWS
keys to authenticate. Toggle `include_external_dependencies`/`ignore_external_dependencies`
and `extra_args` to adjust the Terragrunt invocation.

### Plans on pull requests
`terragrunt-plan.yml` reuses the deploy workflow to run `terragrunt run-all plan`
for both `live/dev` and `live/stg` whenever Terraform HCL changes land in a PR
or when triggered manually. Ensure either the repository variable
`AWS_ROLE_TO_ASSUME` or the secret `aws_role_to_assume` (plus optional static AWS
keys) is defined so the reusable workflow can assume credentials.

### Policy guardrails
OPA policies live under `policy/`. The provided `terraform/state.rego` rules and
tests enforce that any S3 remote state backend enables `encrypt = true` and
specifies a KMS key—mirroring the guardrails executed during the `policy` job in
the validation workflow. Extend these policies as your compliance surface grows.

## License
Licensed under the [Apache License 2.0](LICENSE).
