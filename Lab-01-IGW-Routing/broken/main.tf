# ═══════════════════════════════════════════════════════════════
# BROKEN LAB — VPC Lab 01: Internet Gateway
# ─────────────────────────────────────────
# This configuration is INTENTIONALLY BROKEN.
# The web server will not be reachable from the internet.
# Your mission: find and fix the single misconfiguration.
#
# Hint: The Internet Gateway is attached — but is it routable?
# ═══════════════════════════════════════════════════════════════

# ── VPC ───────────────────────────────────────────────────────

resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "brokenlabs-vpc-lab-01-vpc" }
}

# ── Internet Gateway ──────────────────────────────────────────
# ✅ The IGW is created AND attached to the VPC.
# But is traffic actually routed through it?

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
# ⚠️  BUG IS HERE: The route table exists and is associated
# to the subnet — but there is NO route for internet traffic.
# 0.0.0.0/0 → igw is MISSING.
# Without it, the subnet behaves as a private subnet.

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "brokenlabs-vpc-lab-01-rt" }

  # ❌ NO INTERNET ROUTE — this is the bug!
  # The route table only has the implicit local route:
  # 10.0.0.0/16 → local  (added automatically by AWS)
  #
  # Missing:
  # 0.0.0.0/0 → aws_internet_gateway.lab.id
}

# Route table association — subnet IS associated (not the bug)
resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

# ── Security Group ────────────────────────────────────────────
# ✅ Port 80 is open to the internet — not the bug

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
# ✅ Web server is running on port 80 — not the bug

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
