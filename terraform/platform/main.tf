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
# RBAC for eks-admin / eks-read-only
################################################################################
resource "kubernetes_cluster_role_binding_v1" "eks_admin" {
  metadata {
    name = "eks-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "eks-admin"
  }
}

resource "kubernetes_cluster_role_binding_v1" "eks_read_only" {
  metadata {
    name = "eks-read-only"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "eks-read-only"
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
  principal_arn = "arn:aws:iam::308054409751:role/${local.name}-atlantis"

  depends_on = [module.atlantis_pod_identity]
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
