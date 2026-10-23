variable "name" {
  description = "Security group name"
  type        = string
}

variable "description" {
  description = "Security group description"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ingress_rules" {
  description = "Ingress rules by stable rule name"
  type = map(object({
    protocol                     = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
    description                  = optional(string)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Egress rules by stable rule name"
  type = map(object({
    protocol                     = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    referenced_security_group_id = optional(string)
    description                  = optional(string)
  }))
  default = {}
}
