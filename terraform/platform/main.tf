################################################################################
# EBS CSI Driver
################################################################################
module "ebs_csi_driver_pod_identity" {
  source = "../modules/pod-identity"

  name            = "${local.name}-ebs-csi-driver"
  cluster_name    = local.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"

  policies = {
    ebs = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = local.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.67.1-eksbuild.1"

  configuration_values = jsonencode({
    defaultStorageClass = {
      enabled = true
    }
  })

  depends_on = [module.ebs_csi_driver_pod_identity]
}

################################################################################
# AWS Load Balancer Controller
################################################################################
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${local.name}-aws-load-balancer-controller"
  policy = file("${path.module}/iam-policies/aws-load-balancer-controller.json")
}

module "aws_load_balancer_controller_pod_identity" {
  source = "../modules/pod-identity"

  name            = "${local.name}-aws-load-balancer-controller"
  cluster_name    = local.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"

  policies = {
    controller = aws_iam_policy.aws_load_balancer_controller.arn
  }
}

################################################################################
# eks-admin / eks-read-only
################################################################################
locals {
  rbac_roles = {
    eks-admin     = "cluster-admin"
    eks-read-only = "view"
  }
}

# Not sure who these should be assumble by
# or if they should've got describe cluster permission to get kubeconfig
resource "aws_iam_role" "rbac" {
  for_each = local.rbac_roles

  name = each.key
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::308054409751:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_eks_access_entry" "rbac" {
  for_each = local.rbac_roles

  cluster_name      = local.name
  principal_arn     = aws_iam_role.rbac[each.key].arn
  kubernetes_groups = [each.key]
}

resource "kubernetes_cluster_role_binding_v1" "rbac" {
  for_each = local.rbac_roles

  metadata {
    name = each.key
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = each.value
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = each.key
  }
}

################################################################################
# Atlantis
################################################################################
module "atlantis_pod_identity" {
  source = "../modules/pod-identity"

  name            = "${local.name}-atlantis"
  cluster_name    = local.name
  namespace       = "atlantis"
  service_account = "atlantis"

  policies = {
    admin = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}

resource "aws_eks_access_entry" "atlantis" {
  cluster_name  = local.name
  principal_arn = module.atlantis_pod_identity.role_arn
}

resource "aws_eks_access_policy_association" "atlantis" {
  cluster_name  = local.name
  principal_arn = aws_eks_access_entry.atlantis.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# This Atlantis part is only needed since not using any other secret injection like ESO in this test, otherwise not needd
resource "kubernetes_namespace_v1" "atlantis" {
  metadata {
    name = "atlantis"
  }
}

ephemeral "aws_secretsmanager_secret_version" "github_app_key" {
  secret_id = "atlantis/github-app-key"
}

ephemeral "aws_secretsmanager_secret_version" "webhook_secret" {
  secret_id = "atlantis/webhook-secret"
}

# Secret is kept out of state
resource "kubernetes_secret_v1" "atlantis_vcs" {
  metadata {
    name      = "atlantis-vcs"
    namespace = kubernetes_namespace_v1.atlantis.metadata[0].name
  }

  data_wo = {
    "key.pem"     = ephemeral.aws_secretsmanager_secret_version.github_app_key.secret_string
    github_secret = ephemeral.aws_secretsmanager_secret_version.webhook_secret.secret_string
  }
  data_wo_revision = 1
}

################################################################################
# ArgoCD
################################################################################
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.11.1"
  namespace        = "argocd"
  create_namespace = true

  values = [file("${path.module}/helm-values/argocd.yaml")]
}

resource "helm_release" "argocd_root" {
  name       = "argocd-root"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.7"
  namespace  = "argocd"

  values = [file("${path.module}/helm-values/argocd-root.yaml")]

  depends_on = [helm_release.argocd]
}
