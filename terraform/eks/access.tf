locals {
  account_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::308054409751:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Not sure who these should be assumble by 
# or if they should've got describe cluster permission to get kubeconfig
resource "aws_iam_role" "eks_admin" {
  name               = "eks-admin"
  assume_role_policy = local.account_trust_policy
}

resource "aws_iam_role" "eks_read_only" {
  name               = "eks-read-only"
  assume_role_policy = local.account_trust_policy
}
