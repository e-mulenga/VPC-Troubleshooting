# 🔍 Troubleshooting Guide — VPC Lab 07

## What Makes This Lab Tricky

Unlike Lab 06 (no NAT Gateway at all), this lab HAS a NAT Gateway
that shows as **available** in the console. The route table also points to it.
Everything looks correct — but connectivity still fails.

---

## Diagnosis Steps

### Step 1 — Verify NAT Gateway exists and is available

```bash
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "NatGateways[].{Id:NatGatewayId,State:State,Subnet:SubnetId}"

# Output in BROKEN state:
# [{ "Id": "nat-xxx", "State": "available", "Subnet": "subnet-private-xxx" }]
#                                                       ^^^^^^^^^^^^^^^^^^^^
#                                                       This is the private subnet — BUG!
```

### Step 2 — Compare subnet IDs

```bash
echo "NAT GW subnet:  $(terraform output -raw nat_gateway_subnet_id)"
echo "Public subnet:  $(terraform output -raw public_subnet_id)"
echo "Private subnet: $(terraform output -raw private_subnet_id)"

# BROKEN: NAT GW subnet matches PRIVATE subnet ID
# FIXED:  NAT GW subnet matches PUBLIC subnet ID
```

### Step 3 — Confirm via SSM

```bash
aws ssm start-session --target $(terraform output -raw private_instance_id)

# Once connected:
curl --max-time 10 https://aws.amazon.com
# BROKEN: curl: (6) Could not resolve host
# FIXED:  HTML response received
```

---

## Fix Options

**Option A — Deploy fixed Terraform:**
```bash
cd ../fixed
terraform init && terraform apply
```

**Option B — AWS Console:**
1. VPC → NAT Gateways → select `brokenlabs-vpc-lab-07-nat-gw`
2. Note: you CANNOT move a NAT Gateway to a different subnet
3. You must DELETE the existing NAT Gateway and CREATE a new one in the public subnet
4. Then update the private route table to point to the new NAT Gateway

**This is why Terraform makes it easy** — just change `subnet_id` and `terraform apply`
will destroy the old NAT GW and create a new one in the correct subnet.
