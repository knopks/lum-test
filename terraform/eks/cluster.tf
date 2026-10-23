module "eks_cluster" {
  source = "../modules/eks-cluster"

  name                = module.globals.name
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
    test = { # my current testing user, would remove
      principal_arn = "arn:aws:iam::${module.globals.account_id}:user/lum-test"
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    }
  }
}

resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}
