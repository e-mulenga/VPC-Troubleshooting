# 🔍 Troubleshooting Guide — VPC Lab 08

## Step 1 — Verify Peering Connection Status

```bash
aws ec2 describe-vpc-peering-connections \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-08-peering" \
  --query "VpcPeeringConnections[].{Id:VpcPeeringConnectionId,Status:Status.Code}"

# Expected: [{ "Id": "pcx-xxx", "Status": "active" }]
# The peering is active — not the bug!
```

---

## Step 2 — Check Routes in Both Route Tables

```bash
# VPC A route table
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-08-rt-a" \
  --query "RouteTables[].Routes"

# BROKEN state — missing peering route:
# [
#   { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" },
#   { "DestinationCidrBlock": "0.0.0.0/0",   "GatewayId": "igw-xxx" }
#   ← NO route for 10.1.0.0/16 (VPC B CIDR)!
# ]

# VPC B route table
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-08-rt-b" \
  --query "RouteTables[].Routes"

# BROKEN state — missing peering route:
# [
#   { "DestinationCidrBlock": "10.1.0.0/16", "GatewayId": "local" },
#   { "DestinationCidrBlock": "0.0.0.0/0",   "GatewayId": "igw-xxx" }
#   ← NO route for 10.0.0.0/16 (VPC A CIDR)!
# ]
```

---

## Step 3 — Test Connectivity via SSM

```bash
# Connect to Instance A
aws ssm start-session --target $(terraform output -raw instance_a_id)

# Test ping to Instance B private IP
ping -c 3 $(terraform output -raw instance_b_private_ip)
# BROKEN: ping: connect: Network is unreachable
# FIXED:  64 bytes from 10.1.1.x: icmp_seq=1 ...
```

---

## Fix Options

**Option A — Deploy fixed Terraform:**
```bash
cd ../fixed && terraform init && terraform apply
```

**Option B — AWS CLI:**
```bash
PCX_ID=$(terraform output -raw peering_connection_id)
RT_A=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-08-rt-a" \
  --query "RouteTables[0].RouteTableId" --output text)
RT_B=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-08-rt-b" \
  --query "RouteTables[0].RouteTableId" --output text)

# Add route in VPC A for VPC B traffic
aws ec2 create-route --route-table-id $RT_A \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id $PCX_ID

# Add route in VPC B for VPC A traffic
aws ec2 create-route --route-table-id $RT_B \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id $PCX_ID
```
