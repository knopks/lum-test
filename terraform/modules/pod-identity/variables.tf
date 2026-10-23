variable "name" {
  description = "IAM role name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "namespace" {
  description = "Service account namespace"
  type        = string
}

variable "service_account" {
  description = "Service account name"
  type        = string
}

variable "policies" {
  description = "Policy ARNs to attach, by name"
  type        = map(string)
  default     = {}
}
