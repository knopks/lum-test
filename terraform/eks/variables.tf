variable "initial_cluster_admin" {
  description = "IAM principal (e.g. user/name or role/name) granted cluster admin, used by Terraform to manage Kubernetes resources"
  type        = string
  default     = "user/lum-test"
}
