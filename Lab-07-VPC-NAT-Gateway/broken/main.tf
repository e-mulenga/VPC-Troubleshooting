# ═══════════════════════════════════════════════════════════════
# BROKEN LAB — VPC Lab 07: NAT Gateway Placement
# ────────────────────────────────────────────────
# INTENTIONALLY BROKEN — NAT Gateway placed in PRIVATE subnet.
#
# Unlike Lab 06 (no NAT Gateway), this lab HAS a NAT Gateway.
# The private route table also points to it correctly.
# But the private instance STILL cannot reach the internet.
#
# The bug: subnet_id = aws_subnet.private.id (should be public)
# ═══════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" { state = "available" }

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ── VPC ✅ ────────────────────────────────────────────────────

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "brokenlabs-vpc-lab-07-vpc" }
}

# ── Internet Gateway ✅ ───────────────────────────────────────

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-07-igw" }
}

# ── Public Subnet ✅ ──────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-07-public-subnet", Tier = "Public" }
}

# ── Private Subnet ✅ ─────────────────────────────────────────

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = { Name = "brokenlabs-vpc-lab-07-private-subnet", Tier = "Private" }
}

# ── Elastic IP ✅ ─────────────────────────────────────────────

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.lab]
  tags       = { Name = "brokenlabs-vpc-lab-07-nat-eip" }
}

# ── NAT Gateway ⚠️  BUG IS HERE ──────────────────────────────
# The NAT Gateway is placed in the PRIVATE subnet.
# A NAT Gateway needs internet access to forward traffic.
# Private subnet has no IGW route — NAT GW is effectively isolated.
# Private instance traffic hits the NAT GW but goes nowhere.

resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.private.id   # ❌ WRONG: should be public subnet
  depends_on    = [aws_internet_gateway.lab]
  tags          = { Name = "brokenlabs-vpc-lab-07-nat-gw" }
}

# ── Public Route Table ✅ ─────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-07-public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Private Route Table ✅ (route exists — not the bug) ───────

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-07-private-rt" }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ── IAM Role for SSM ✅ ───────────────────────────────────────

resource "aws_iam_role" "ssm" {
  name = "brokenlabs-vpc-lab-07-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = { Name = "brokenlabs-vpc-lab-07-ssm-role" }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "brokenlabs-vpc-lab-07-ssm-profile"
  role = aws_iam_role.ssm.name
}

# ── Security Group — Private ✅ ───────────────────────────────

resource "aws_security_group" "private" {
  name        = "brokenlabs-vpc-lab-07-private-sg"
  description = "Private instance — VPC internal only"
  vpc_id      = aws_vpc.lab.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "All traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "brokenlabs-vpc-lab-07-private-sg" }
}

# ── Private EC2 Instance ✅ ───────────────────────────────────

resource "aws_instance" "private" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = false

  user_data = file("${path.module}/../scripts/user_data_private.sh")

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = { Name = "brokenlabs-vpc-lab-07-private", Tier = "Private" }
}
