################################################################################
# Cluster IAM Role
################################################################################
resource "aws_iam_role" "this_cluster" {
  name = "${var.name}-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this_cluster" {
  role       = aws_iam_role.this_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

################################################################################
# KMS Key for Kubernetes Secrets Encryption
################################################################################
resource "aws_kms_key" "this" {
  description             = "${var.name} EKS secrets encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}-eks"
  target_key_id = aws_kms_key.this.key_id
}

################################################################################
# Cluster
################################################################################
resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.this_cluster.arn

  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.this.arn
    }
    resources = ["secrets"]
  }

  depends_on = [aws_iam_role_policy_attachment.this_cluster]
}

################################################################################
# Pod Identity Agent Add-on
################################################################################
resource "aws_eks_addon" "this_pod_identity_agent" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = var.addon_versions.pod_identity_agent
}

################################################################################
# Networking Add-ons
################################################################################
resource "aws_eks_addon" "this_vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = var.addon_versions.vpc_cni

  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })
}

resource "aws_eks_addon" "this_kube_proxy" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "kube-proxy"
  addon_version = var.addon_versions.kube_proxy
}

################################################################################
# Node IAM Role
################################################################################
resource "aws_iam_role" "this_node" {
  name = "${var.name}-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.this_node.name
  policy_arn = each.value
}

################################################################################
# Node Group
################################################################################
resource "aws_eks_node_group" "this" {
  cluster_name           = aws_eks_cluster.this.name
  node_group_name_prefix = "${var.name}-default-"
  node_role_arn          = aws_iam_role.this_node.arn
  subnet_ids             = var.subnet_ids

  instance_types = var.node_group.instance_types
  ami_type       = var.node_group.ami_type
  disk_size      = var.node_group.disk_size
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = var.node_group.min_size
    max_size     = var.node_group.max_size
    desired_size = var.node_group.desired_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.this_node,
    aws_eks_addon.this_vpc_cni,
    aws_eks_addon.this_kube_proxy,
  ]
}

################################################################################
# CoreDNS Add-on
################################################################################
resource "aws_eks_addon" "this_coredns" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "coredns"
  addon_version = var.addon_versions.coredns

  depends_on = [aws_eks_node_group.this]
}

################################################################################
# Access Entries
################################################################################
resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  kubernetes_groups = each.value.kubernetes_groups
}

resource "aws_eks_access_policy_association" "this" {
  for_each = { for k, v in var.access_entries : k => v if v.policy_arn != null }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.this[each.key].principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type = "cluster"
  }
}
