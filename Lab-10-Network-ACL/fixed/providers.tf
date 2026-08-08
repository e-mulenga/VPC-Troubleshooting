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
      Project = "broken-labs-vpc-lab-10"
      ManagedBy = "Terraform"
      Owner = "Emmanuel Mulenga"
      Lab = "VPC-NACL-Ephemeral-Ports"
      Series = "Broken-Labs-VPC"
    }
  }
}
