
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "availability_zones" {
  value = data.aws_availability_zones.az.names
}

output "number_of_azs" {
  value = local.available_az_in_region
}

output "public_subnet_cidrs" {
  value = local.public_subnets
}

output "private_subnet_cidrs" {
  value = local.private_subnets
}