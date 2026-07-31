# ═══════════════════════════════════════════════════════════════
# FIXED LAB — VPC Lab 03: Security Group
# ────────────────────────────────────────
# Fix applied: Changed Security Group inbound rule from port 8080
# to port 80 — matching the web server's listening port.
#
# Change from broken version:
#   from_port = 8080 → 80
#   to_port   = 8080 → 80
# ═══════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" { state = "available" }

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "brokenlabs-vpc-lab-03-vpc" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-03-igw" }
}

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-03-subnet" }
}

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-03-rt" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

resource "aws_network_acl" "lab" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.lab.id]
  tags       = { Name = "brokenlabs-vpc-lab-03-nacl" }
}

resource "aws_network_acl_rule" "inbound_allow_http" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "inbound_allow_ephemeral" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "outbound_allow_all" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# ── Security Group ✅ FIXED ───────────────────────────────────

resource "aws_security_group" "lab" {
  name        = "brokenlabs-vpc-lab-03-sg"
  description = "Broken Labs VPC Lab 03 security group"
  vpc_id      = aws_vpc.lab.id

  # ✅ THE FIX: Changed port from 8080 to 80.
  # Port 80 is the standard HTTP port used by the web server.
  # Security Groups implicitly deny all traffic not explicitly allowed.
  ingress {
    description = "HTTP on correct port 80"
    from_port   = 80            # ✅ Fixed from 8080 → 80
    to_port     = 80            # ✅ Fixed from 8080 → 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "brokenlabs-vpc-lab-03-sg" }
}

resource "aws_instance" "lab" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.lab.id
  vpc_security_group_ids      = [aws_security_group.lab.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/../scripts/user_data.sh")

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = { Name = "brokenlabs-vpc-lab-03" }
}
