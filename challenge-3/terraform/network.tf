
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "azs" {}

# Use first 3 zones of whatever region it is
locals {
  first_three_zones = slice(data.aws_availability_zones.azs.names, 0, 3)
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}"
  }
}