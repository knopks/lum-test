provider "github" {
  owner = "knopks"

  dynamic "app_auth" {
    for_each = var.github_app_id != "" ? [1] : []
    content {
      id              = var.github_app_id
      installation_id = var.github_app_installation_id
      pem_file        = file(var.github_app_pem_file)
    }
  }
}

provider "aws" {
  region              = module.globals.region
  allowed_account_ids = [module.globals.account_id]

  default_tags {
    tags = module.globals.tags
  }
}
