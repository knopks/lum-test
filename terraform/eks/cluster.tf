module "eks_cluster" {
  source = "../modules/eks-cluster"

  name                = local.name
  subnet_ids          = module.vpc.public_subnet_ids
  public_access_cidrs = ["0.0.0.0/0"]

  node_group = {
    instance_types = ["m7i-flex.large"]
    ami_type       = "AL2023_x86_64_STANDARD"
    disk_size      = 20
    min_size       = 1
    max_size       = 2
    desired_size   = 1
  }

  access_entries = {
    eks-admin = {
      principal_arn     = aws_iam_role.eks_admin.arn
      kubernetes_groups = ["eks-admin"]
    }
    eks-read-only = {
      principal_arn     = aws_iam_role.eks_read_only.arn
      kubernetes_groups = ["eks-read-only"]
    }
    lum-test = { # temporary user I made for myself
      principal_arn = "arn:aws:iam::308054409751:user/lum-test"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    }
  }
}
