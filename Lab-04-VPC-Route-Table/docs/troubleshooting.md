# 🔍 Troubleshooting Guide — VPC Lab 04

## Diagnosis Checklist

Layers 1–7 all pass from Labs 01–03. The bug is in Layer 8.

---

### Layers 1–7 — All Pass

```bash
# Layer 1: Instance running?          ✅
# Layer 2: Has public IP?             ✅
# Layer 3: IGW attached?              ✅
# Layer 4: Route 0.0.0.0/0 → IGW?    ✅ (route EXISTS in custom RT)
# Layer 5: NACL allows port 80?       ✅
# Layer 6: SG allows port 80?         ✅
# Layer 7: Web server running?        ✅
```

---

### Layer 8 — Route Table Association ⬅️ BUG HERE

```bash
# Check which route table the subnet is using
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=$(terraform output -raw subnet_id)" \
  --query "RouteTables[].{Id:RouteTableId,Routes:Routes,Associations:Associations}"

# BROKEN state output — subnet uses DEFAULT route table:
# {
#   "Id": "rtb-xxxxxxxx",   ← this is the VPC DEFAULT route table
#   "Routes": [
#     { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" }
#     ← NO 0.0.0.0/0 → IGW route!
#   ]
# }

# Check the CUSTOM route table
aws ec2 describe-route-tables \
  --route-table-ids $(terraform output -raw route_table_id) \
  --query "RouteTables[].{Routes:Routes,Associations:Associations}"

# BROKEN state — custom RT has the route but NO subnet association:
# {
#   "Routes": [
#     { "DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local" },
#     { "DestinationCidrBlock": "0.0.0.0/0",   "GatewayId": "igw-xxx" }  ← route exists ✅
#   ],
#   "Associations": []   ← no subnets associated ❌
# }
```

---

### Fix Options

**Option A — AWS Console:**
1. EC2 → Route Tables → `brokenlabs-vpc-lab-04-rt`
2. Subnet associations → Edit subnet associations
3. Select `brokenlabs-vpc-lab-04-subnet` → Save

**Option B — AWS CLI:**
```bash
aws ec2 associate-route-table \
  --route-table-id $(terraform output -raw route_table_id) \
  --subnet-id $(terraform output -raw subnet_id)
```

**Option C — Deploy fixed Terraform:**
```bash
cd ../fixed
terraform init && terraform apply
```

---

### Quick Verify After Fix

```bash
curl -I http://$(terraform output -raw instance_public_ip)/
# Expected: HTTP/1.0 200 OK
```
