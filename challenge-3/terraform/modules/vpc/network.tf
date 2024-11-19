
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}


locals {
  available_az_in_region = length(data.aws_availability_zones.az.names)
  
  # something smart to split the vpc equally to a set of public and private subnets, 
  # the newbits are added to the vpc cidr to get the subnet cidr
  subnet_newbits = ceil(log(local.available_az_in_region * 2, 2))
  
  # for each available AZ we make a subnet of an equal size from the vpc cidr, for example 4 public and 4 private subnets.
  public_subnets = [
    for index in range(local.available_az_in_region) :
    cidrsubnet(var.vpc_cidr, local.subnet_newbits, index)
  ]
  
  private_subnets = [
    for index in range(local.available_az_in_region) :
    cidrsubnet(var.vpc_cidr, local.subnet_newbits, index + local.available_az_in_region)
  ]
}


resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
    Project = "${var.project_name}"
    Owner = "DevOps team"
  }
}

resource "aws_subnet" "public" {
  count             = local.available_az_in_region
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.public_subnets[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]
  
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Project = "${var.project_name}"
    Owner = "DevOps team"
    Type = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = local.available_az_in_region
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Project = "${var.project_name}"
    Owner = "DevOps team"
    Type = "Private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-main-igw"
    Project = "${var.project_name}"
    Owner = "DevOps team"
  }
}

# EIPs for NAT gateways in each az 
resource "aws_eip" "nat" {
  count = local.available_az_in_region
  domain = "vpc"
}

# NAT gateways, can use just one in a region for minor cost savings, if it's not a production environment
resource "aws_nat_gateway" "main" {
  count         = local.available_az_in_region
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gateway-${count.index + 1}"
    Project = "${var.project_name}"
    Owner = "DevOps team"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  # in public subnets the default route goes to igw 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
    Project = "${var.project_name}"
    Owner = "DevOps team"
  }
}

resource "aws_route_table" "private" {
  count  = local.available_az_in_region
  vpc_id = aws_vpc.vpc.id

  # in private subnets the default route goes to NAT of the same subnet
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
    Project = "${var.project_name}"
    Owner = "DevOps team"
  }
}

# attaching the route tables to subnets 
resource "aws_route_table_association" "public" {
  count          = local.available_az_in_region
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = local.available_az_in_region
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
