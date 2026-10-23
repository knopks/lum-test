terraform {
  required_version = "~> 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }

  backend "s3" {
    bucket       = "knopks-lum-test-tfstate"
    key          = "eks/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
