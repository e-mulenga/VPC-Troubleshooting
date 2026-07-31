# ═══════════════════════════════════════════════════════════════
# BROKEN LAB — VPC Lab 06: NAT Gateway
# ──────────────────────────────────────
# INTENTIONALLY BROKEN — the private instance cannot reach the internet.
#
# This lab introduces two-tier architecture (public + private subnets).
# The private instance needs outbound internet access but:
#   ❌ No NAT Gateway created
#   ❌ No route in private route table to the internet
#
# The private instance CAN be accessed via SSM Session Manager
# (using VPC endpoints or SSM PrivateLink) but CANNOT reach the internet.
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
  tags = { Name = "brokenlabs-vpc-lab-06-vpc" }
}

# ── Internet Gateway ✅ ───────────────────────────────────────

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-06-igw" }
}

# ── Public Subnet ✅ ──────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-06-public-subnet", Tier = "Public" }
}

# ── Private Subnet ✅ ─────────────────────────────────────────

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = { Name = "brokenlabs-vpc-lab-06-private-subnet", Tier = "Private" }
}

# ── Public Route Table ✅ ─────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-06-public-rt" }
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

# ── Private Route Table ⚠️  BUG IS HERE ──────────────────────
# The private route table exists but has NO internet route.
# Without a NAT Gateway and corresponding route, the private
# instance cannot send ANY outbound traffic to the internet.

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-06-private-rt" }

  # ❌ Only has local route (implicit)
  # Missing: 0.0.0.0/0 → nat_gateway
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ❌ NAT Gateway is MISSING entirely
# Both of these are required for private subnet internet access:
#
# resource "aws_eip" "nat" { domain = "vpc" }
#
# resource "aws_nat_gateway" "lab" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public.id
# }
#
# resource "aws_route" "private_internet" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.lab.id
# }

# ── NACL — Public Subnet ✅ ───────────────────────────────────

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.public.id]
  tags       = { Name = "brokenlabs-vpc-lab-06-public-nacl" }
}

resource "aws_network_acl_rule" "public_inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_inbound_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_outbound_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# ── NACL — Private Subnet ✅ ──────────────────────────────────

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.private.id]
  tags       = { Name = "brokenlabs-vpc-lab-06-private-nacl" }
}

resource "aws_network_acl_rule" "private_inbound_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_outbound_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# ── IAM Role for SSM Access ✅ ────────────────────────────────

resource "aws_iam_role" "ssm" {
  name = "brokenlabs-vpc-lab-06-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = { Name = "brokenlabs-vpc-lab-06-ssm-role" }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "brokenlabs-vpc-lab-06-ssm-profile"
  role = aws_iam_role.ssm.name
}

# ── Security Group — Private Instance ✅ ──────────────────────

resource "aws_security_group" "private" {
  name        = "brokenlabs-vpc-lab-06-private-sg"
  description = "Private instance security group — VPC internal traffic only"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "All traffic from within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "brokenlabs-vpc-lab-06-private-sg" }
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

  tags = { Name = "brokenlabs-vpc-lab-06-private", Tier = "Private" }
}
