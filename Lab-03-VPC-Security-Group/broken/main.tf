# ═══════════════════════════════════════════════════════════════
# BROKEN LAB — VPC Lab 03: Security Group
# ────────────────────────────────────────
# INTENTIONALLY BROKEN — the website will not load.
#
# Labs 01 and 02 bugs are now FIXED:
#   ✅ IGW attached and route 0.0.0.0/0 → IGW exists
#   ✅ NACL allows port 80 inbound
#   ✅ Web server running on port 80
#
# The bug is in the Security Group inbound rule.
# Hint: What port is the web server actually listening on?
# ═══════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" { state = "available" }

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ── VPC ───────────────────────────────────────────────────────

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "brokenlabs-vpc-lab-03-vpc" }
}

# ── Internet Gateway ✅ ───────────────────────────────────────

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-03-igw" }
}

# ── Subnet ✅ ─────────────────────────────────────────────────

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-03-subnet" }
}

# ── Route Table with IGW Route ✅ ─────────────────────────────

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

# ── NACL ✅ ───────────────────────────────────────────────────

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

# ── Security Group ⚠️  BUG IS HERE ───────────────────────────

resource "aws_security_group" "lab" {
  name        = "brokenlabs-vpc-lab-03-sg"
  description = "Broken Labs VPC Lab 03 security group"
  vpc_id      = aws_vpc.lab.id

  # ❌ BUG: Port 8080 is allowed — but the web server listens on port 80.
  # Security Groups use implicit deny — if port 80 is not listed, it is blocked.
  # Browsers request port 80 (HTTP default) → SG has no matching rule → DENIED.
  ingress {
    description = "Wrong port — 8080 instead of 80"
    from_port   = 8080          # ← BUG: should be 80
    to_port     = 8080          # ← BUG: should be 80
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

# ── EC2 Web Server ✅ ─────────────────────────────────────────

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
