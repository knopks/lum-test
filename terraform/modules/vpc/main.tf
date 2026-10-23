################################################################################
# VPC
################################################################################
resource "aws_vpc" "this_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

################################################################################
# Default Security Group
################################################################################
resource "aws_default_security_group" "this_default" {
  vpc_id = aws_vpc.this_vpc.id

  tags = {
    Name = "${var.name}-default"
  }
}

################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this_internet_gateway" {
  tags = {
    Name = "${var.name}-internet-gateway"
  }
}

resource "aws_internet_gateway_attachment" "this_internet_gateway_attachment" {
  internet_gateway_id = aws_internet_gateway.this_internet_gateway.id
  vpc_id              = aws_vpc.this_vpc.id
}

################################################################################
# Route Tables
################################################################################
resource "aws_route_table" "this_internet_gw" {
  vpc_id = aws_vpc.this_vpc.id

  tags = {
    Name = "${var.name}-internet-gw"
  }
}

################################################################################
# Internet Gateway Routes
################################################################################
resource "aws_route" "this_internet_gw_route" {
  route_table_id         = aws_route_table.this_internet_gw.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this_internet_gateway.id
}

################################################################################
# Public Subnets
################################################################################
module "this_public_subnets" {
  source = "../subnets"
  vpc_id = aws_vpc.this_vpc.id

  subnets                 = var.public_subnets
  route_table_id          = aws_route_table.this_internet_gw.id
  map_public_ip_on_launch = true
  service                 = "${var.name}-public"
}
