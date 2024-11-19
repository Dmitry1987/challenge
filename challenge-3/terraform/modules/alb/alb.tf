resource "aws_security_group" "alb" {
  name_prefix = "${var.project}-${var.environment}-alb-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = {
    Name        = "${var.project}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project
    Owner = "DevOps team"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
  enable_deletion_protection = false
  enable_http2              = true

  tags = {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project
    Owner = "DevOps team"
  }
}
