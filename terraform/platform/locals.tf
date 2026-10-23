locals {
  name = "lum-test"
}

data "aws_eks_cluster" "this" {
  name = local.name
}

ephemeral "aws_eks_cluster_auth" "this" {
  name = local.name
}
