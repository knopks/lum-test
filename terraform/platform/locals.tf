module "globals" {
  source = "../modules/globals"
}

data "aws_eks_cluster" "this" {
  name = module.globals.name
}

ephemeral "aws_eks_cluster_auth" "this" {
  name = module.globals.name
}
