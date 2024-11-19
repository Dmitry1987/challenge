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
  source = "./modules/alb"
  
  internal = true 
  # we're making internal LB for databases 
  subnet_ids = module.vpc.public_subnet_ids
  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  project  = var.project

  # access to the LB can be a whitelist of Cloudflare IP addresses or something like that,
  # but such whitelist has to be maintained in a lambda function to keep being updated immediately when 
  # a published IP list is changing on Cloudflare or any other service that acts as the edge and proxies to the ALB 
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Public access on HTTPS port"
    },
    {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}