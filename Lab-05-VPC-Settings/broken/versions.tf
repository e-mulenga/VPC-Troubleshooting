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
      Project   = "broken-labs-vpc-lab-05"
      ManagedBy = "Terraform"
      Owner     = "Emmanuel Mulenga"
      Lab       = "VPC-DNS-Settings"
      Series    = "Broken-Labs-VPC"
    }
  }
}
