variable "name" {
  description = "Name prefix"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets by name"
  type = map(object({
    cidr = string
    az   = string
  }))
}
