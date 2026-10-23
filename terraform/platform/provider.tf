provider "aws" {
  region              = "eu-north-1"
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Project = "lum-test"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = ephemeral.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = ephemeral.aws_eks_cluster_auth.this.token
  }
}
