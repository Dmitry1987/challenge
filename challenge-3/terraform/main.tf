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

# module "alb" {
#   source = "./modules/alb"
  
#   internal = true 
#   # we're making internal LB for databases 
#   subnet_ids = module.vpc.public_subnet_ids
#   aws_region  = var.aws_region
#   vpc_id    = module.vpc.vpc_id
#   environment = var.environment
#   project  = var.project

#   # access to the LB can be a whitelist of Cloudflare IP addresses or something like that,
#   # but such whitelist has to be maintained in a lambda function to keep being updated immediately when 
#   # a published IP list is changing on Cloudflare or any other service that acts as the edge and proxies to the ALB 
#   security_group_rules = [
#     {
#       type        = "ingress"
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "Public access on HTTPS port"
#     },
#     {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#       description = "Allow all outbound traffic"
#     }
#   ]
# }


# Switching from my own alb module to existing one, because lazy to add listeners and target groups in there, it ended up more than a 2 hour task :D
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${var.project}-${var.environment}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids

  # Security Group for default httpd 
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # will not be adding the ACM certificate generation and DNS validation in this challenge, but that would be the next step to correctly configure this.
  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "${var.project}-${var.environment}-web"
      }
    }
  }

  target_groups = {
    "${var.project}-${var.environment}-web" = {
      name_prefix      = "${var.project}-${var.environment}-web"
      protocol         = "HTTP"
      port             = 80
      target_type        = "instance"
      vpc_id             = module.vpc.vpc_id
      autoscaling_group_name = module.asg.autoscaling_group_name 
    }
  }

  tags = {
    ASG = "${var.project}-${var.environment}-asg"
    Environment = var.environment
    Project     = var.project
    Owner = "DevOps team"
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"

  # Autoscaling group
  name = "${var.project}-${var.environment}-asg"

  min_size                  = 0
  max_size                  = 1
  # the desired_capacity in this module can be ignored in subsequent applies so the value we set here will be applied only once
  desired_capacity          = 1
  ignore_desired_capacity_changes = true 
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

  # user data to install httpd service and run on start of instance,
  # better to use from file of course as "base64encode(templatefile(${path.module}/user-data.sh" if it's a longer script 
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt update
    apt install -y httpd
    systemctl start httpd
    systemctl enable httpd
    EOF
  )

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