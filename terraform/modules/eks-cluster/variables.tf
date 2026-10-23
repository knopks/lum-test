variable "name" {
  description = "Cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.37"
}

variable "addon_versions" {
  description = "EKS add-on versions"
  type = object({
    vpc_cni            = string
    kube_proxy         = string
    coredns            = string
    pod_identity_agent = string
  })
  default = {
    vpc_cni            = "v1.22.4-eksbuild.3"
    kube_proxy         = "v1.37.0-eksbuild.22"
    coredns            = "v1.14.7-eksbuild.11"
    pod_identity_agent = "v1.3.10-eksbuild.3"
  }
}

variable "subnet_ids" {
  description = "Subnets for the cluster and nodes"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_group" {
  description = "Worker node group"
  type = object({
    instance_types = list(string)
    ami_type       = string
    disk_size      = number
    min_size       = number
    max_size       = number
    desired_size   = number
  })
}

variable "access_entries" {
  description = "Cluster access entries"
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), [])
    policy_arn        = optional(string)
  }))
  default = {}
}
