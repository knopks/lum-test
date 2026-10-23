provider "aws" {
  region              = module.globals.region
  allowed_account_ids = [module.globals.account_id]

  default_tags {
    tags = module.globals.tags
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
