# ═══════════════════════════════════════════════════════════════
# BROKEN LAB — VPC Lab 05: VPC Settings
# ──────────────────────────────────────
# INTENTIONALLY BROKEN — the DNS-based URL will not work.
#
# All previous bugs are FIXED:
#   ✅ IGW attached with 0.0.0.0/0 → IGW route
#   ✅ Subnet associated to route table
#   ✅ NACL allows port 80
#   ✅ Security Group allows port 80
#   ✅ Web server running on port 80
#
# The bug: enable_dns_hostnames = false on the VPC.
# EC2 instances will NOT receive public DNS hostnames.
# The output URL using public_dns will be empty.
# ═══════════════════════════════════════════════════════════════

data "aws_availability_zones" "available" { state = "available" }

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ── VPC ⚠️  BUG IS HERE ───────────────────────────────────────

resource "aws_vpc" "lab" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = false  # ❌ BUG: Must be true for public DNS names
                                 # With false: instances get no public DNS hostname
                                 # The output URL will be http:// (empty string)

  tags = { Name = "brokenlabs-vpc-lab-05-vpc" }
}

# ── Internet Gateway ✅ ───────────────────────────────────────

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-05-igw" }
}

# ── Subnet ✅ ─────────────────────────────────────────────────

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-05-subnet" }
}

# ── Route Table with IGW Route ✅ ─────────────────────────────

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-05-rt" }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}

# ── Route Table Association ✅ ────────────────────────────────

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

# ── NACL ✅ ───────────────────────────────────────────────────

resource "aws_network_acl" "lab" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.lab.id]
  tags       = { Name = "brokenlabs-vpc-lab-05-nacl" }
}

resource "aws_network_acl_rule" "inbound_http" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "inbound_ephemeral" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 200
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "outbound_all" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# ── Security Group ✅ ─────────────────────────────────────────

resource "aws_security_group" "lab" {
  name        = "brokenlabs-vpc-lab-05-sg"
  description = "Broken Labs VPC Lab 05 security group"
  vpc_id      = aws_vpc.lab.id

  ingress {
    description = "HTTP port 80 from internet"
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

  tags = { Name = "brokenlabs-vpc-lab-05-sg" }
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

  tags = { Name = "brokenlabs-vpc-lab-05" }
}
