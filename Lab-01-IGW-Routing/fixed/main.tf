# ═══════════════════════════════════════════════════════════════
# FIXED LAB — VPC Lab 01: Internet Gateway
# ─────────────────────────────────────────
# This is the FIXED version of the broken lab.
# The single fix: adding the internet route to the route table.
#
# Change from broken version:
#   Added: aws_route.internet_access
#   Route: 0.0.0.0/0 → aws_internet_gateway.lab.id
# ═══════════════════════════════════════════════════════════════

# ── VPC ───────────────────────────────────────────────────────

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "brokenlabs-vpc-lab-01-vpc" }
}

# ── Internet Gateway ──────────────────────────────────────────

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-01-igw" }
}

# ── Public Subnet ─────────────────────────────────────────────

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "brokenlabs-vpc-lab-01-subnet" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ── Route Table ───────────────────────────────────────────────

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-01-rt" }
}

# ✅ THE FIX: This route was missing in the broken version.
# This single line enables internet access for the subnet.
# Without it, the Internet Gateway is attached but unreachable.

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"       # All internet traffic
  gateway_id             = aws_internet_gateway.lab.id  # Via the IGW
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

# ── Security Group ────────────────────────────────────────────

resource "aws_security_group" "lab" {
  name        = "brokenlabs-vpc-lab-01-sg"
  description = "Broken Labs VPC Lab 01 security group"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "brokenlabs-vpc-lab-01-sg" }
}

# ── EC2 Web Server ────────────────────────────────────────────

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "lab" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.lab.id
  vpc_security_group_ids      = [aws_security_group.lab.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/../scripts/user_data.sh")

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = { Name = "brokenlabs-vpc-lab-01" }
}
