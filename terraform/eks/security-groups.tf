################################################################################
# Atlantis ALB Security Group
################################################################################
data "github_ip_ranges" "this" {}

module "atlantis_alb_security_group" {
  source = "../modules/security-group"

  name        = "${local.name}-atlantis-alb"
  description = "Atlantis webhook ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    for cidr in data.github_ip_ranges.this.hooks_ipv4 : cidr => {
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_ipv4   = cidr
      description = "GitHub webhooks"
    }
  }

  egress_rules = {
    atlantis-pods = {
      protocol                     = "tcp"
      from_port                    = 4141
      to_port                      = 4141
      referenced_security_group_id = module.eks_cluster.node_security_group_id
      description                  = "Atlantis pods"
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_atlantis_alb" {
  security_group_id            = module.eks_cluster.node_security_group_id
  referenced_security_group_id = module.atlantis_alb_security_group.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 4141
  to_port                      = 4141
  description                  = "Atlantis ALB to Atlantis pods"
}
