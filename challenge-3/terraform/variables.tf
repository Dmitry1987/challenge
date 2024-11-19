variable "project" {
  type = string
  default = "default"
}

variable "environment" {
  type = string
  default = "production"
}

variable "aws_region" {
  type = string
  default = "eu-west-1"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "instance_size" {
  type = string
  default = "t3.small"
}
