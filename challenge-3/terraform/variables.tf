variable "project" {
  default = "default"
}

variable "environment" {
  default = "production"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "instance_size" {
  default = "t3.small"
}
