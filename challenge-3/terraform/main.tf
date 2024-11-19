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
  vpc_id    = module.vpc.vpc_id
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

# RDS will use existing module 
module "postgres" {
  source  = "terraform-aws-modules/rds-aurora/aws"

  name           = "${var.project}-aurora-postgres"
  engine         = "aurora-postgresql"
  engine_version = "14.5"
  instance_class = "db.r6g.large"
  instances = {
    one = {}
    2 = {
      instance_class = "db.r6g.large"
    }
  }

  vpc_id    = module.vpc.vpc_id
  db_subnet_group_name = "${var.project}-db-subnet-group"

  # Allow all the internal subnets which were created earlier
  security_group_rules = {
    default_ingress_rules = {
      cidr_blocks = module.vpc.private_subnet_ids
    }
  }

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10

  tags = {
    Environment = var.environment
    Project     = var.project
    Owner = "DevOps team"
  }
}