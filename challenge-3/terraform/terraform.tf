terraform {
  required_version = ">= 1.9" 
  backend "s3" {
    bucket               = "devopschallenge-tf-state"
    key                  = "infra-demo"
    region               = "eu-west-1"
    workspace_key_prefix = "workspace"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
