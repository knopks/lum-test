variable "github_owner" {
  description = "GitHub user or organization that owns the repository"
  type        = string
  default     = "knopks"
}

variable "repository_name" {
  description = "Name of the assignment repository"
  type        = string
  default     = "lum-test"
}

variable "enable_atlantis_webhook" {
  description = "Create the Atlantis webhook"
  type        = bool
  default     = false
}

variable "github_app_id" {
  description = "GitHub App ID, empty to use GITHUB_TOKEN"
  type        = string
  default     = ""
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID"
  type        = string
  default     = ""
}

variable "github_app_pem_file" {
  description = "Path to the GitHub App private key"
  type        = string
  default     = ""
}
