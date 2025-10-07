# GitOps for EKS (dev) — Bootstrap and Add‑ons

Opinionated, production‑grade GitOps repo for a **dev** EKS cluster. Pinned Helm charts, IRSA bindings, Karpenter ready, Kyverno guardrails, External Secrets wired to AWS Secrets Manager, cert‑manager with Route53 DNS‑01.

## Placeholders to replace
- `<org>` — your GitHub/Git provider org or user
- `<account_id_dev>` — AWS account ID for the dev account
- `<route53_zone_id>` — Hosted Zone ID used for DNS‑01
- `<domain>` — base domain (e.g., example.com)
- `<acm_email>` — ACME/Let’s Encrypt contact email
- `<karpenter_controller_role_arn>` — IAM role ARN created by Terraform for Karpenter controller (IRSA)
- `<external_secrets_role_arn>` — IAM role ARN for External Secrets ServiceAccount
- `<alb_controller_role_arn>` — IAM role ARN for AWS Load Balancer Controller ServiceAccount

## Glossary
- **Argo CD** — GitOps controller that syncs the manifests in this repo.
- **IRSA** — IAM Roles for Service Accounts; grants pods AWS permissions.
- **Karpenter** — Kubernetes node autoscaler tuned for EKS.
- **External Secrets** — Operator that mirrors AWS Secrets Manager secrets.
- **cert-manager** — Issues and renews TLS certs via Let’s Encrypt DNS‑01.
- **Kyverno** — Kubernetes policy engine enforcing security guardrails.
- **AWS Load Balancer Controller** — Provisions ALBs/NLBs for services.
- **ADOT Collector** — OpenTelemetry collector shipping cluster telemetry.
- **Atlantis** — Pull-request automation for Terraform/Terragrunt plans.

## Instructions
### Prerequisites
1. Replace the placeholders above with environment‑specific values.
2. Provision networking, cluster, and IAM prerequisites using the Terragrunt
   configuration under `live/` (see `live/README.md`).

### Bootstrap Argo CD
1. Point `kubectl` at the new EKS cluster.
2. Apply the Argo CD bootstrap manifests:
   ```bash
   kubectl apply -f apps/argo/bootstrap/argocd-install.yaml
   kubectl apply -f apps/argo/bootstrap/projects.yaml
   kubectl apply -f apps/argo/bootstrap/app-of-apps.yaml
   ```
3. Log into Argo CD, approve the `dev-bootstrap` application (if manual sync is
   required), and verify the downstream apps reconcile successfully.

### Ongoing operations
1. Edit manifests or Helm values in this repo, commit, and push.
2. Allow Argo CD to sync automatically (self-heal is enabled) or trigger a
   manual sync when testing.
3. Monitor controllers (cert-manager, External Secrets, Karpenter, etc.) to
   confirm desired state after each change.

## Structure
- `apps/argo/bootstrap` — Argo CD install + app‑of‑apps
- `apps/clusters/dev` — cluster overlay: namespaces + platform add‑ons
- `apps/services` — sample service to validate ingress/TLS/secrets

## Notes
- Controllers are installed via Argo Applications (Helm charts).
- IRSA is required: Terraform must have created the IAM roles and OIDC provider.
- cert‑manager uses Route53 DNS‑01; switch issuers from staging to prod when ready.
- Karpenter: controller is installed here; provisioners and nodeclasses are provided.
- Security: Kyverno blocks `:latest`, audits missing seccomp; add more policies for prod.

## Upgrade policy
- Bump `targetRevision` chart versions explicitly via PR.
- Syncs are automatic with prune + selfHeal for drift resilience.
