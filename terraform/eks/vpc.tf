module "vpc" {
  source = "../modules/vpc"

  name     = local.name
  vpc_cidr = "10.0.0.0/16"

  public_subnets = {
    a = { cidr = "10.0.0.0/24", az = "eu-north-1a" }
    b = { cidr = "10.0.1.0/24", az = "eu-north-1b" }
  }
}
