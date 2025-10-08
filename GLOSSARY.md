# Glossary

## Infrastructure Provisioning
- Infrastructure as Code (IaC) — [Docs](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code-intro) — Practice of managing infrastructure via declarative code; the entire repository (`live/`, `apps/`) applies IaC so changes are versioned and reproducible.
- Terraform — [Docs](https://developer.hashicorp.com/terraform/docs) — HashiCorp provisioning engine Terragrunt wraps to create AWS networking, EKS, and IAM resources defined under `live/`.
- Terragrunt — [Docs](https://terragrunt.gruntwork.io/docs/) — Thin wrapper used here to orchestrate shared inputs, remote state, and module reuse across environments like `live/dev` and `live/stg`.
- `terragrunt run-all` — [Docs](https://terragrunt.gruntwork.io/docs/reference/cli-options/#run-all) — Command Terragrunt workflows (CI, Atlantis) use to fan out `init/plan/apply` across dependency graphs such as `live/dev/us-east-1`.
- Terraform AWS Modules (VPC, EKS, Karpenter, IAM) — [Registry](https://registry.terraform.io/namespaces/terraform-aws-modules) — Community modules sourced in Terragrunt stacks to provision VPC networking, EKS control planes, Karpenter prerequisites, and IAM roles.
- Remote State (S3 backend) — [Docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3) — Terraform backend configured in `_env.hcl` files to store state securely in S3 with locking/encryption requirements enforced by policy.
- `terraform fmt` — [Docs](https://developer.hashicorp.com/terraform/cli/commands/fmt) — Formatting command enforced in CI to keep HCL canonical before Terragrunt plans.
- `terragrunt hclfmt` — [Docs](https://terragrunt.gruntwork.io/docs/reference/cli-options/#hclfmt) — Formatter invoked locally and in CI to normalize Terragrunt configuration style.

## AWS Cloud Platform
- Amazon Web Services (AWS) — [Docs](https://aws.amazon.com/what-is-aws/) — Cloud provider hosting all infrastructure components (network, compute, identity) targeted by the Terraform stacks.
- AWS Identity and Access Management (IAM) — [Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) — Service managing roles and policies; Terragrunt modules create execution roles (e.g., `terraform-exec`) and IRSA bindings.
- IAM Roles for Service Accounts (IRSA) — [Docs](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) — Mechanism enabling Kubernetes service accounts (Atlantis, External Secrets, ALB controller) to assume IAM roles provisioned in `live/us-east-1/iam`.
- AWS OpenID Connect federation — [Docs](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers) — GitHub Actions integration used in workflows to assume AWS roles without static credentials.
- Amazon Elastic Kubernetes Service (EKS) — [Docs](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) — Managed Kubernetes control plane provisioned via `terraform-aws-modules/eks`.
- EKS Managed Node Groups — [Docs](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) — Worker node pools defined in the cluster Terragrunt stack for system workloads.
- Amazon Virtual Private Cloud (VPC) — [Docs](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) — Networking construct created with the VPC module to supply subnets, routing, and security groups for the cluster.
- NAT Gateway — [Docs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) — Managed egress gateway enabled in the VPC settings for private subnets reaching the internet.
- VPC Flow Logs — [Docs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html) — Logging feature configured to push rejected traffic logs to CloudWatch for auditing.
- Amazon CloudWatch Logs — [Docs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html) — Destination for VPC flow logs and other telemetry captured by the infrastructure.
- Amazon Simple Storage Service (S3) — [Docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) — Backend for Terraform state and persistence layers such as the Atlantis PVC.
- AWS Key Management Service (KMS) — [Docs](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html) — Encryption service whose CMKs secure Terraform state per `_env.hcl` configuration and OPA policy.
- AWS Secrets Manager — [Docs](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) — Secret store read by External Secrets to materialize Kubernetes secrets for Atlantis and workloads.
- Amazon Route 53 — [Docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html) — DNS provider leveraged by cert-manager and ingress hosts once `<domain>` placeholders are set.
- Amazon DynamoDB — [Docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html) — Optional state-lock table referenced in README guidance for hardening Terraform remote state.

## Kubernetes Platform & Add-ons
- Kubernetes — [Docs](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) — Container orchestration platform provided by EKS; manifests under `apps/` target this control plane.
- GitOps — [Docs](https://opengitops.dev/) — Operational model implemented via Argo CD to sync cluster state from the `apps/` Git repository.
- Argo CD — [Docs](https://argo-cd.readthedocs.io/en/stable/) — GitOps controller bootstrapped through `apps/argo/bootstrap` to reconcile add-ons and workloads.
- Kustomize — [Docs](https://kubectl.docs.kubernetes.io/references/kustomize/) — Configuration overlay tool used in `apps/clusters/<env>` to compose namespaces, add-ons, and services.
- Helm — [Docs](https://helm.sh/docs/) — Package manager referenced by Argo Applications to install charts like cert-manager, Karpenter, and the AWS Load Balancer Controller.
- Atlantis — [Docs](https://www.runatlantis.io/docs/) — Automation service deployed via Helm to execute Terragrunt plans/applies from pull requests.
- Karpenter — [Docs](https://karpenter.sh/docs/) — Open-source node provisioning controller; Terraform config in `live/.../eks/karpenter` prepares IAM/OIDC, and GitOps installs the Helm chart plus NodeClass.
- Karpenter NodeClass — [Docs](https://karpenter.sh/docs/concepts/nodeclass/) — CRD defined in `apps/clusters/dev/addons/karpenter/provisioners` specifying AMI family, subnets, and tags for provisioned nodes.
- AWS Load Balancer Controller — [Docs](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/) — Controller deploying ALBs for Kubernetes ingresses, configured via IRSA annotated service accounts.
- Kubernetes Ingress — [Docs](https://kubernetes.io/docs/concepts/services-networking/ingress/) — API used by Atlantis and the sample API to expose services through AWS ALBs with TLS.
- cert-manager — [Docs](https://cert-manager.io/docs/) — Certificate controller issuing ACME certs via Route 53 DNS-01; values are pinned in `apps/clusters/dev/addons/cert-manager`.
- External Secrets Operator — [Docs](https://external-secrets.io/latest/introduction/what-is-external-secrets-operator/) — Controller synchronizing AWS Secrets Manager data into Kubernetes secrets, with manifests under `apps/clusters/dev/addons/external-secrets`.
- AWS Distro for OpenTelemetry (ADOT) — [Docs](https://aws-otel.github.io/docs/introduction) — AWS-supported OpenTelemetry distribution installed to collect cluster logs via the `adot-collector` application.
- OpenTelemetry Collector — [Docs](https://opentelemetry.io/docs/collector/) — Component configured by the ADOT chart to receive and forward telemetry (`apps/clusters/dev/addons/adot-collector`).
- AWS EBS CSI Driver — [Docs](https://github.com/kubernetes-sigs/aws-ebs-csi-driver#readme) — CSI plugin installed for block storage volumes used by Kubernetes workloads.
- AWS EFS CSI Driver — [Docs](https://github.com/kubernetes-sigs/aws-efs-csi-driver#readme) — CSI plugin enabling pods to mount EFS file systems if required by future workloads.
- Kyverno — [Docs](https://kyverno.io/docs/) — Policy engine deployed via Argo to enforce baseline guardrails on pods and images.
- Pod Security Standards (PSA) — [Docs](https://kubernetes.io/docs/concepts/security/pod-security-standards/) — Kubernetes security levels applied via namespace labels (restricted/baseline) across overlays.
- Kubernetes ServiceAccount — [Docs](https://kubernetes.io/docs/concepts/security/service-accounts/) — Identity objects annotated with IAM roles (IRSA) for controllers like Atlantis and External Secrets.
- NGINX — [Docs](https://nginx.org/en/docs/) — Web server image powering the sample API deployment used to validate ingress and secret injection.

## Automation, CI/CD & Quality
- GitHub Actions — [Docs](https://docs.github.com/actions) — CI platform executing Terragrunt validation, plans, and deploy workflows defined under `.github/workflows/`.
- `hashicorp/setup-terraform@v3` — [Docs](https://github.com/hashicorp/setup-terraform) — Action installing Terraform CLI in CI jobs before running fmt and validation.
- `gruntwork-io/terragrunt-action@v3` — [Docs](https://github.com/gruntwork-io/terragrunt-action) — Action used to install specific Terragrunt versions for plans and applies.
- `aws-actions/configure-aws-credentials@v4` — [Docs](https://github.com/aws-actions/configure-aws-credentials) — Action that acquires AWS credentials via OIDC or static keys for Terragrunt workflows.
- `bridgecrewio/checkov-action@v12` — [Docs](https://github.com/bridgecrewio/checkov-action) — Action running Checkov scans on Terraform/Terragrunt code during the security job.
- Checkov — [Docs](https://www.checkov.io/) — IaC static analysis scanner validating Terraform against security best practices; SARIF output feeds GitHub code scanning.
- SARIF — [Docs](https://learn.microsoft.com/azure/devops/security-tools/sarif-support) — Standard format used to upload Checkov findings to GitHub Security via `upload-sarif`.
- GitHub reusable workflows — [Docs](https://docs.github.com/actions/using-workflows/reusing-workflows) — Mechanism behind `terragrunt-deploy.yml`, letting other jobs or repos trigger parameterized run-all executions.
- Terragrunt Plan Workflow — [Docs](https://docs.github.com/actions/using-workflows/events-that-trigger-workflows) — Pull-request workflow invoking the reusable deploy file to produce `terragrunt run-all plan` outputs for `dev` and `stg`.
- Atlantis Workflows — [Docs](https://www.runatlantis.io/docs/workflows.html) — Custom Terragrunt plan/apply steps defined in `atlantis-example/atlantis.yaml` and mirrored in the Helm values for in-cluster automation.

## Policy & Compliance
- Open Policy Agent (OPA) — [Docs](https://www.openpolicyagent.org/docs/latest/) — Policy engine enforced in the `policy` CI job to validate Terraform state settings.
- Rego — [Docs](https://www.openpolicyagent.org/docs/latest/policy-language/) — Declarative policy language used in `policy/terraform/state.rego` to require encrypted Terraform state.
- `opa test` — [Docs](https://www.openpolicyagent.org/docs/latest/policy-testing/) — Testing command executed in CI against `state_test.rego` to ensure Rego policies cover expected scenarios.
- Policy as Code — [Docs](https://www.openpolicyagent.org/docs/latest/policy-as-code/) — Approach implemented here by versioning Rego policies alongside infrastructure code to guard remote state configuration.
