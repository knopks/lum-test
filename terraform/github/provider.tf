provider "github" {
  owner = var.github_owner

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
  region              = "eu-north-1"
  allowed_account_ids = [var.aws_account_id]

  default_tags {
    tags = {
      Project = "lum-test"
    }
  }
}
