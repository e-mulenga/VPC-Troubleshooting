# ═══════════════════════════════════════════════════════════════
# BROKEN LAB — VPC Lab 02: Network ACL
# ─────────────────────────────────────
# INTENTIONALLY BROKEN — the website will not load.
#
# Everything from Lab 01 is now FIXED:
#   ✅ IGW attached to VPC
#   ✅ Route table has 0.0.0.0/0 → IGW
#   ✅ Subnet associated to route table
#   ✅ Security group allows port 80
#   ✅ Web server running
#
# The bug is in the Network ACL rule ordering.
# Hint: NACLs are stateless and process rules lowest-number-first.
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
  tags = { Name = "brokenlabs-vpc-lab-02-vpc" }
}

# ── Internet Gateway ✅ ───────────────────────────────────────

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-02-igw" }
}

# ── Subnet ✅ ─────────────────────────────────────────────────

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "brokenlabs-vpc-lab-02-subnet" }
}

# ── Route Table with IGW Route ✅ ─────────────────────────────
# Lab 01 bug is fixed — route exists

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-02-rt" }
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

# ── Network ACL ⚠️  BUG IS HERE ──────────────────────────────

resource "aws_network_acl" "lab" {
  vpc_id     = aws_vpc.lab.id
  subnet_ids = [aws_subnet.lab.id]
  tags       = { Name = "brokenlabs-vpc-lab-02-nacl" }
}

# ❌ BUG: Rule 90 DENIES port 80 BEFORE Rule 100 can ALLOW it.
# NACLs evaluate rules in ascending order — lowest number first.
# Rule 90 is evaluated before Rule 100.
# The DENY matches first → traffic is blocked → website unreachable.
resource "aws_network_acl_rule" "inbound_deny_http" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 90           # ← evaluated FIRST (lower number wins)
  protocol       = "tcp"
  rule_action    = "deny"       # ← BLOCKS all port 80 traffic
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# This rule NEVER executes because Rule 90 matches first
resource "aws_network_acl_rule" "inbound_allow_http" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 100          # ← evaluated SECOND (too late)
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Outbound — allow all (not the bug)
resource "aws_network_acl_rule" "outbound_allow_all" {
  network_acl_id = aws_network_acl.lab.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

# ── Security Group ✅ ─────────────────────────────────────────

resource "aws_security_group" "lab" {
  name        = "brokenlabs-vpc-lab-02-sg"
  description = "Broken Labs VPC Lab 02 security group"
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

  tags = { Name = "brokenlabs-vpc-lab-02-sg" }
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

  tags = { Name = "brokenlabs-vpc-lab-02" }
}
