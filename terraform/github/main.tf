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
