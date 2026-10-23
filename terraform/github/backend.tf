terraform {
  required_version = "~> 1.17.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }

  backend "s3" {
    bucket       = "knopks-lum-test-tfstate"
    key          = "github/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
