# 🔍 Troubleshooting Guide — VPC Lab 01

## Systematic Diagnosis Checklist

Work through each layer in order. Stop when you find the failure point.

---

### Step 1 — Is the EC2 instance running?

```bash
# Get instance state
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query "Reservations[].Instances[].State.Name" \
  --output text
# Expected: running
```

---

### Step 2 — Does the instance have a public IP?

```bash
terraform output instance_public_ip
# Expected: a public IP address (not empty or 'null')
```

---

### Step 3 — Is the security group correct?

```bash
# Check inbound rules on the security group
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-01-sg" \
  --query "SecurityGroups[].IpPermissions"
# Expected: port 80, protocol tcp, cidr 0.0.0.0/0
```

---

### Step 4 — Is the route table associated to the subnet?

```bash
aws ec2 describe-route-tables \
  --route-table-ids $(terraform output -raw route_table_id) \
  --query "RouteTables[].Associations"
# Expected: SubnetId matches the lab subnet
```

---

### Step 5 — Does the route table have a route to the IGW? ⬅️ BUG HERE

```bash
aws ec2 describe-route-tables \
  --route-table-ids $(terraform output -raw route_table_id) \
  --query "RouteTables[].Routes"
# Expected (FIXED):
#   { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" }
#   { "DestinationCidrBlock": "0.0.0.0/0",   "GatewayId": "igw-xxxx" }
#
# What you see in BROKEN state (the bug):
#   { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" }
#   ← 0.0.0.0/0 route is MISSING
```

---

### Step 6 — Is the IGW attached to the VPC?

```bash
aws ec2 describe-internet-gateways \
  --internet-gateway-ids $(terraform output -raw internet_gateway_id) \
  --query "InternetGateways[].Attachments"
# Expected: State = "available", VpcId matches lab VPC
```

---

### Step 7 — Is the web server process running?

```bash
# Connect via SSM Session Manager (no SSH key required)
aws ssm start-session --target $(terraform output -raw instance_id)

# Once connected:
systemctl status lab-web
curl localhost:80
```

---

## Quick Fix Command

```bash
# From the broken/ directory — migrate to fixed config
cd ../fixed
terraform init
terraform apply
```

Or manually in the AWS Console:
1. EC2 → Route Tables → `brokenlabs-vpc-lab-01-rt`
2. Routes → Edit routes → Add route
3. Destination: `0.0.0.0/0` | Target: Internet Gateway → select the lab IGW
4. Save → test the URL
