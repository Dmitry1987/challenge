# defaults for the VPC module 
variable "project_name" {
  type = string
  default = "defaults"
}

variable "vpc_cidr" {
  type = string
  default = "10.1.0.0/16"
}
