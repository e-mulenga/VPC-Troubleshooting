# 🔍 Troubleshooting Guide — VPC Lab 06

## This Lab is Different

Labs 01–05 all involved a single public EC2 instance.
Lab 06 introduces **two-tier architecture** — public and private subnets.

The private instance has **no public IP** — you cannot reach it directly.
Use **AWS Systems Manager Session Manager** to connect:

```bash
aws ssm start-session \
  --target $(terraform output -raw private_instance_id) \
  --region us-east-1
```

---

## Testing Outbound Connectivity

Once connected via SSM:

```bash
# Test DNS resolution
nslookup aws.amazon.com

# Test HTTP outbound
curl -I http://example.com
# BROKEN: curl: (6) Could not resolve host OR connection timeout
# FIXED:  HTTP/1.1 200 OK

# Test HTTPS outbound
curl -I https://aws.amazon.com
# BROKEN: curl: (6) Could not resolve host
# FIXED:  HTTP/2 200

# Test ICMP (ping) — may be blocked by security policies
ping -c 3 8.8.8.8
# BROKEN: Network is unreachable
# FIXED:  64 bytes from 8.8.8.8
```

---

## Diagnosis — Private Route Table

```bash
# Check what routes the private subnet is using
aws ec2 describe-route-tables \
  --route-table-ids $(terraform output -raw private_route_table_id) \
  --query "RouteTables[].Routes"

# BROKEN state:
# [
#   { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" }
#   ← Only local route — no internet route!
# ]

# FIXED state:
# [
#   { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" },
#   { "DestinationCidrBlock": "0.0.0.0/0",   "NatGatewayId": "nat-xxx" } ✅
# ]

# Check if a NAT Gateway exists in the VPC
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "NatGateways[].{Id:NatGatewayId,State:State,SubnetId:SubnetId}"

# BROKEN: Empty list — no NAT Gateways
# FIXED:  [{ "Id": "nat-xxx", "State": "available", "SubnetId": "subnet-public" }]
```

---

## Fix Options

**Option A — Deploy fixed Terraform:**
```bash
cd ../fixed
terraform init && terraform apply
# Wait 1-2 minutes for NAT Gateway to become available
```

**Option B — Manual via AWS Console:**
1. VPC → Elastic IPs → Allocate Elastic IP address
2. VPC → NAT Gateways → Create NAT Gateway
   - Subnet: select the PUBLIC subnet
   - Elastic IP: select the allocated EIP
3. VPC → Route Tables → select private route table
4. Routes → Edit routes → Add route
   - Destination: `0.0.0.0/0`
   - Target: NAT Gateway → select the new NAT GW
5. Save → wait 1-2 minutes → test connectivity
