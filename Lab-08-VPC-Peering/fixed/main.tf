# ═══════════════════════════════════════════════════════════════
# FIXED LAB — VPC Lab 08: VPC Peering
# ──────────────────────────────────────
# Fix applied: Added peering routes to BOTH route tables.
#
# Changes from broken version:
#   ADDED: aws_route.vpc_a_to_vpc_b
#   ADDED: aws_route.vpc_b_to_vpc_a
# ═══════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" { state = "available" }

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_vpc" "vpc_a" {
  cidr_block           = var.vpc_a_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "brokenlabs-vpc-lab-08-vpc-a" }
}

resource "aws_internet_gateway" "vpc_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags   = { Name = "brokenlabs-vpc-lab-08-igw-a" }
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-08-subnet-a" }
}

resource "aws_route_table" "vpc_a" {
  vpc_id = aws_vpc.vpc_a.id
  tags   = { Name = "brokenlabs-vpc-lab-08-rt-a" }
}

resource "aws_route" "vpc_a_internet" {
  route_table_id         = aws_route_table.vpc_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_a.id
}

# ✅ THE FIX — Route 1: VPC A → VPC B via peering connection
resource "aws_route" "vpc_a_to_vpc_b" {
  route_table_id            = aws_route_table.vpc_a.id
  destination_cidr_block    = var.vpc_b_cidr              # 10.1.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.lab.id
}

resource "aws_route_table_association" "vpc_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.vpc_a.id
}

resource "aws_vpc" "vpc_b" {
  cidr_block           = var.vpc_b_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "brokenlabs-vpc-lab-08-vpc-b" }
}

resource "aws_internet_gateway" "vpc_b" {
  vpc_id = aws_vpc.vpc_b.id
  tags   = { Name = "brokenlabs-vpc-lab-08-igw-b" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-08-subnet-b" }
}

resource "aws_route_table" "vpc_b" {
  vpc_id = aws_vpc.vpc_b.id
  tags   = { Name = "brokenlabs-vpc-lab-08-rt-b" }
}

resource "aws_route" "vpc_b_internet" {
  route_table_id         = aws_route_table.vpc_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_b.id
}

# ✅ THE FIX — Route 2: VPC B → VPC A via peering connection
resource "aws_route" "vpc_b_to_vpc_a" {
  route_table_id            = aws_route_table.vpc_b.id
  destination_cidr_block    = var.vpc_a_cidr              # 10.0.0.0/16
  vpc_peering_connection_id = aws_vpc_peering_connection.lab.id
}

resource "aws_route_table_association" "vpc_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.vpc_b.id
}

# ── VPC Peering Connection ✅ ─────────────────────────────────

resource "aws_vpc_peering_connection" "lab" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true
  tags        = { Name = "brokenlabs-vpc-lab-08-peering" }
}

# ── IAM Role for SSM ✅ ───────────────────────────────────────

resource "aws_iam_role" "ssm" {
  name = "brokenlabs-vpc-lab-08-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow"; Action = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" } }]
  })
  tags = { Name = "brokenlabs-vpc-lab-08-ssm-role" }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "brokenlabs-vpc-lab-08-ssm-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_security_group" "sg_a" {
  name        = "brokenlabs-vpc-lab-08-sg-a"
  description = "VPC A instance security group"
  vpc_id      = aws_vpc.vpc_a.id
  ingress {
    from_port = 0; to_port = 0; protocol = "-1"
    cidr_blocks = [var.vpc_b_cidr]
    description = "All traffic from VPC B"
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "brokenlabs-vpc-lab-08-sg-a" }
}

resource "aws_security_group" "sg_b" {
  name        = "brokenlabs-vpc-lab-08-sg-b"
  description = "VPC B instance security group"
  vpc_id      = aws_vpc.vpc_b.id
  ingress {
    from_port = 0; to_port = 0; protocol = "-1"
    cidr_blocks = [var.vpc_a_cidr]
    description = "All traffic from VPC A"
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "brokenlabs-vpc-lab-08-sg-b" }
}

resource "aws_instance" "instance_a" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_a.id
  vpc_security_group_ids      = [aws_security_group.sg_a.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = true
  user_data = file("${path.module}/../scripts/user_data.sh")
  metadata_options { http_tokens = "required"; http_endpoint = "enabled" }
  tags = { Name = "brokenlabs-vpc-lab-08-instance-a", VPC = "A" }
}

resource "aws_instance" "instance_b" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_b.id
  vpc_security_group_ids      = [aws_security_group.sg_b.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = true
  user_data = file("${path.module}/../scripts/user_data.sh")
  metadata_options { http_tokens = "required"; http_endpoint = "enabled" }
  tags = { Name = "brokenlabs-vpc-lab-08-instance-b", VPC = "B" }
}
