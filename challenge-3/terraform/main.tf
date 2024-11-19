provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  project_name  = var.project
}

# balancer for RDS database
module "alb" {
  source = "./modules/vpc"
  
  internal = true 
  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  project  = var.project
  # TODO pass the correct AZ subnets for security groups, 
  # which we generated in the VPC module since they are always different length in each region, 
  # allow only private subnet access to the database LB. 
}