# 🔍 Troubleshooting Guide — VPC Lab 03

## Diagnosis Checklist

Layers 1–6 all pass from Labs 01 and 02. The bug is in Layer 7.

---

### Layers 1–6 — All Pass

```bash
# Layer 1: Instance running?     ✅
# Layer 2: Has public IP?        ✅
# Layer 3: Route table has IGW?  ✅
# Layer 4: Subnet associated?    ✅
# Layer 5: NACL allows port 80?  ✅
# Layer 6: IGW attached?         ✅
```

---

### Layer 7 — Security Group Inbound Rules ⬅️ BUG HERE

```bash
# Inspect Security Group inbound rules
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id) \
  --query "SecurityGroups[].IpPermissions"

# What you see in BROKEN state:
# [
#   {
#     "FromPort": 8080,    ← WRONG — web server uses port 80
#     "ToPort": 8080,
#     "IpProtocol": "tcp",
#     "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
#   }
# ]

# What you expect in FIXED state:
# [
#   {
#     "FromPort": 80,      ← CORRECT
#     "ToPort": 80,
#     "IpProtocol": "tcp",
#     "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
#   }
# ]
```

---

### Fix Options

**Option A — AWS Console:**
1. EC2 → Security Groups → `brokenlabs-vpc-lab-03-sg`
2. Inbound rules → Edit inbound rules
3. Change port 8080 to port 80
4. Save rules → refresh the web page

**Option B — AWS CLI:**
```bash
SG_ID=$(terraform output -raw security_group_id)

# Remove the wrong rule
aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0

# Add the correct rule
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

**Option C — Deploy the fixed Terraform config:**
```bash
cd ../fixed
terraform init && terraform apply
```

---

## Quick Verification

```bash
# After fixing — test connectivity
curl -I http://$(terraform output -raw instance_public_ip)/
# Expected: HTTP/1.0 200 OK
```
