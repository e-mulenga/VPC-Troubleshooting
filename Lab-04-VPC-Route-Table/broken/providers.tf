terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "broken-labs-vpc-lab-04"
      ManagedBy = "Terraform"
      Owner     = "Emmanuel Mulenga"
      Lab       = "VPC-Route-Table-Association"
      Series    = "Broken-Labs-VPC"
    }
  }
}
