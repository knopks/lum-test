output "public_subnet_ids" {
  value = module.this_public_subnets.subnet_ids

  depends_on = [
    aws_internet_gateway_attachment.this_internet_gateway_attachment,
    aws_route.this_internet_gw_route,
  ]
}
