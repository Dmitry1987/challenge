# defaults for the VPC module 
variable "project_name" {
  default = "defaults"
}

variable "environment" {
  default = "dev"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}
