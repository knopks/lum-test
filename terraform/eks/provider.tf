provider "aws" {
  region              = module.globals.region
  allowed_account_ids = [module.globals.account_id]

  default_tags {
    tags = module.globals.tags
  }
}

provider "github" {}
