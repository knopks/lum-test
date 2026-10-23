# lum-test

Homework assignment: EKS and Atlantis on AWS, deployed with Terraform and Helm.

## Task Requirements

| Requirement | Where |
|---|---|
| 1 VPC, 2 subnets, 1 EKS cluster | `terraform/eks` |
| Worker group, min 1 / max 2 | EKS managed node group in `terraform/eks` |
| `eks-admin` / `eks-read-only` | IAM roles, access entries and RBAC bindings in `terraform/platform` |
| Atlantis with Terraform and Helm | Helm chart deployed by ArgoCD, which Terraform installs |
| Atlantis on this repository | GitHub App + webhook in `terraform/github` |

## Architecture

- **Terraform** provisions the AWS infrastructure (VPC, EKS, IAM) and installs ArgoCD.
- **ArgoCD** deploys the cluster applications in `argocd/`: AWS Load Balancer Controller and Atlantis.
- **Atlantis** runs `terraform plan` and `terraform apply` for each stack from pull requests.

First deploy runs from a local computer then changes can go through pull requests.

## Layout

```
cloudformation/     Terraform state bucket
terraform/
  modules/          Shared modules
  github/           Repository, Atlantis secrets and webhook
  eks/              VPC, cluster, nodes
  platform/         Add-ons, eks-admin / eks-read-only, ArgoCD
argocd/             ArgoCD apps and their Helm values
atlantis.yaml       Atlantis projects
```

## Initial setup

Required:

- AWS profile `lum`
- `GITHUB_TOKEN` environment variable
- GitHub App for Atlantis, installed on repo

```bash
make bootstrap
make init apply STACK=github ARGS=-var=enable_atlantis_webhook=false

aws secretsmanager put-secret-value --secret-id atlantis/github-app-key --secret-string file://lum-test-atlantis.2026-10-23.private-key.pem
aws secretsmanager put-secret-value --secret-id atlantis/webhook-secret --secret-string "$(openssl rand -hex 32)"

make init apply STACK=eks
make init apply STACK=platform

# once ArgoCD has deployed Atlantis
make apply STACK=github
```

## Compromises

- **State bucket outside the pipeline.** Atlantis doesn't manage the CloudFormation stack, so it can only be updated by rerunning `make bootstrap` locally. Production would deploy it from CI.
- **Public subnets, no NAT.** Only 2 subnets were allowed, so nodes have public IPs (dont accept inbound traffic).
- **Public EKS API endpoint.** Would keep it private behind a VPN.
- **HTTP webhook.** No domain for a certificate; requests are signed and limited to GitHub's IPs.
- **Public images and charts.** Production would use mirrors (e.g. ECR pull-through cache) and image scanning.
- **Atlantis is admin everywhere** and runs in the cluster it manages. Production would use least privilege and a separate management cluster.
- **eks-admin eks-read-only RBAC in Terraform.** Kept next to the IAM roles and access entries for simplicity. Used Kubernetes RBAC instead of EKS access policies (`AmazonEKSClusterAdminPolicy` / `AmazonEKSViewPolicy`), as I wasn't sure those would count. Would manage RBAC through ArgoCD, with only IAM and access entries in Terraform.
- **eks-read-only uses the built-in `view` role.** It only covers namespaced resources, so nodes, PVs, storage classes, CRDs and cluster roles aren't visible. Would add a ClusterRole for cluster-scoped reads, still excluding secrets.
- **Public repository.** Anyone could comment `atlantis apply` on an open PR. Would use a private repo with Atlantis restricted to a team.
- **No PR approval before apply.** Would change Atlantis to require approval.
- **Webhook secret in Terraform state.** GitHub provider has no way to keep it out if done through IaC, not Github App.
