# Outputs from the VPC module 

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "availability_zones" {
  value = module.vpc.availability_zones
}

output "nat_gateway_ips" {
  value = module.vpc.nat_gateway_ips
}