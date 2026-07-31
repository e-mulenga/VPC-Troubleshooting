variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_a_cidr" {
  description = "CIDR block for VPC A"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_b_cidr" {
  description = "CIDR block for VPC B"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_a_cidr" {
  description = "CIDR block for Subnet A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_b_cidr" {
  description = "CIDR block for Subnet B"
  type        = string
  default     = "10.1.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
