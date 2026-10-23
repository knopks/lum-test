module "vpc" {
  source = "../modules/vpc"

  name     = module.globals.name
  vpc_cidr = "10.0.0.0/16"

  public_subnets = {
    a = { cidr = "10.0.0.0/24", az = "${module.globals.region}a" }
    b = { cidr = "10.0.1.0/24", az = "${module.globals.region}b" }
  }
}
