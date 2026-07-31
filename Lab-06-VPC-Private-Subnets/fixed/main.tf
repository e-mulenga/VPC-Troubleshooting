# ═══════════════════════════════════════════════════════════════
# FIXED LAB — VPC Lab 06: NAT Gateway
# ──────────────────────────────────────
# Fix applied: Added NAT Gateway, Elastic IP and private internet route.
#
# Changes from broken version:
#   ADDED: aws_eip.nat
#   ADDED: aws_nat_gateway.lab (in public subnet)
#   ADDED: aws_route.private_internet (0.0.0.0/0 → nat_gateway)
# ═══════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" { state = "available" }

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "brokenlabs-vpc-lab-06-vpc" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-06-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-06-public-subnet", Tier = "Public" }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  tags = { Name = "brokenlabs-vpc-lab-06-private-subnet", Tier = "Private" }
}

# ── NAT Gateway ✅ THE FIX ────────────────────────────────────
# NAT Gateway must be placed in the PUBLIC subnet.
# It uses an Elastic IP to masquerade private instance traffic.

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.lab]
  tags       = { Name = "brokenlabs-vpc-lab-06-nat-eip" }
}

resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id   # ← Must be PUBLIC subnet
  depends_on    = [aws_internet_gateway.lab]
  tags          = { Name = "brokenlabs-vpc-lab-06-nat-gw" }
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

# ── Private Route Table ✅ THE FIX ────────────────────────────

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-06-private-rt" }
}

# ✅ THE FIX: Route all outbound traffic through the NAT Gateway.
# Private instances can now reach the internet for updates/downloads.
# Return traffic comes back via NAT Gateway — private IP never exposed.
resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ── NACLs ✅ ──────────────────────────────────────────────────

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.public.id]
  tags       = { Name = "brokenlabs-vpc-lab-06-public-nacl" }
}

resource "aws_network_acl_rule" "public_inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 100; protocol = "tcp"; rule_action = "allow"
  egress = false; cidr_block = "0.0.0.0/0"; from_port = 80; to_port = 80
}

resource "aws_network_acl_rule" "public_inbound_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 110; protocol = "tcp"; rule_action = "allow"
  egress = false; cidr_block = "0.0.0.0/0"; from_port = 443; to_port = 443
}

resource "aws_network_acl_rule" "public_inbound_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 200; protocol = "tcp"; rule_action = "allow"
  egress = false; cidr_block = "0.0.0.0/0"; from_port = 1024; to_port = 65535
}

resource "aws_network_acl_rule" "public_outbound_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number = 100; protocol = "-1"; rule_action = "allow"
  egress = true; cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.private.id]
  tags       = { Name = "brokenlabs-vpc-lab-06-private-nacl" }
}

resource "aws_network_acl_rule" "private_inbound_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number = 100; protocol = "-1"; rule_action = "allow"
  egress = false; cidr_block = var.vpc_cidr
}

resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number = 200; protocol = "tcp"; rule_action = "allow"
  egress = false; cidr_block = "0.0.0.0/0"; from_port = 1024; to_port = 65535
}

resource "aws_network_acl_rule" "private_outbound_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number = 100; protocol = "-1"; rule_action = "allow"
  egress = true; cidr_block = "0.0.0.0/0"
}

# ── IAM Role for SSM ✅ ───────────────────────────────────────

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
  description = "Private instance — VPC internal only"
  vpc_id      = aws_vpc.lab.id

  ingress {
    from_port = 0; to_port = 0; protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "All traffic from within VPC"
  }

  egress {
    from_port = 0; to_port = 0; protocol = "-1"
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

  depends_on = [aws_nat_gateway.lab]
}
