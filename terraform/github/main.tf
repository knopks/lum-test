################################################################################
# Repository
################################################################################
resource "github_repository" "this" {
  name        = var.repository_name
  description = "Homework Assignment"
  visibility  = "public"

  has_issues   = true
  has_wiki     = false
  has_projects = false

  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_squash_merge     = true
  delete_branch_on_merge = true

  lifecycle {
    prevent_destroy = true
  }
}

################################################################################
# Atlantis Secrets
################################################################################
resource "aws_secretsmanager_secret" "atlantis_github_app_key" {
  name                    = "atlantis/github-app-key"
  description             = "Atlantis GitHub App private key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "atlantis_webhook_secret" {
  name                    = "atlantis/webhook-secret"
  description             = "Atlantis webhook secret"
  recovery_window_in_days = 0
}

################################################################################
# Atlantis Webhook
################################################################################
data "aws_lb" "atlantis" {
  count = var.enable_atlantis_webhook ? 1 : 0

  name = "${var.repository_name}-atlantis"
}

data "aws_secretsmanager_secret_version" "atlantis_webhook_secret" {
  count = var.enable_atlantis_webhook ? 1 : 0

  secret_id = aws_secretsmanager_secret.atlantis_webhook_secret.id
}


# Webhook secret gets written to tfstate here
resource "github_repository_webhook" "atlantis" {
  count = var.enable_atlantis_webhook ? 1 : 0

  repository = github_repository.this.name
  active     = true
  events     = ["pull_request", "pull_request_review", "push", "issue_comment"]

  configuration {
    url          = "http://${data.aws_lb.atlantis[0].dns_name}/events"
    content_type = "json"
    secret       = data.aws_secretsmanager_secret_version.atlantis_webhook_secret[0].secret_string
  }
}
