variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "service" {
  description = "What the subnets are used for"
  type        = string
}

variable "subnets" {
  description = "Subnets by name"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "route_table_id" {
  description = "Route table for the subnets"
  type        = string
}

variable "map_public_ip_on_launch" {
  description = "Give instances a public IP"
  type        = bool
  default     = false
}
