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


module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "${var.project}-${var.environment}-asg"

  min_size                  = 0
  max_size                  = 1
  # the desired should always be set at null, otherwise it will try to adjust the existing groups every time on apply,
  # I'm surprised the official example shows a '1'
  desired_capacity          = null
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  # which subnets to use 
  vpc_zone_identifier       = module.vpc.private_subnet_ids

  launch_template_name        = "${var.project}-${var.environment}-lt"
  launch_template_description = "Launch template default"
  update_default_version      = true

  # probably our specific ones from the Pacler baked images, or the latest ubuntu. 
  # here using the latest Ubuntu from the auto finder by filters, in ami-select.tf 
  image_id          = data.aws_ami.ubuntu.id
  instance_type     = var.instance_size
  ebs_optimized     = true
  enable_monitoring = true
  # I don't like the AZ rebalance terminating instances and getting into infinite loops when coupled with k8s autoscaler that fights back :D 
  # also if nodes run at 90-100% routinely for a long time, it's worth to suspend the 'ReplaceUnhealthy' since the internal ec2 health check will always be unhappy about it.
  suspended_processes = ["AZRebalance"]

  # no need to add IAM roles, since in the challenge we're not asked to access the S3 explicitly, :D 

  # default disks
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp3"
      }
    }
  ]

  # These will not always work, depends on instance type, c7 for example is already single thread per physical core and can't be adjusted, etc'
  cpu_options = {
    core_count       = 1
    threads_per_core = 1
  }

  # spots in order to not waste money when testing this terraform! 
  instance_market_options = {
    market_type = "spot"
    spot_options = {
      block_duration_minutes = 10
    }
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = {
        ASG = "${var.project}-${var.environment}-asg"
        Environment = var.environment
        Project     = var.project
        Owner = "DevOps team"
      }
    },
    {
      resource_type = "volume"
      tags          = {
        ASG = "${var.project}-${var.environment}-asg"
        Environment = var.environment
        Project     = var.project
        Owner = "DevOps team"
      }
    },
    {
      resource_type = "spot-instances-request"
      tags          = {
        ASG = "${var.project}-${var.environment}-asg"
        Environment = var.environment
        Project     = var.project
        Owner = "DevOps team"
      }
    }
  ]

  tags = {
    ASG = "${var.project}-${var.environment}-asg"
    Environment = var.environment
    Project     = var.project
    Owner = "DevOps team"
  }
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