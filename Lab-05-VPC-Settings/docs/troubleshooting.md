# 🔍 Troubleshooting Guide — VPC Lab 05

## Diagnosis Checklist

Layers 1–8 all pass from Labs 01–04.
The bug is at the VPC settings level — Layer 0 (foundational).

---

### All Previous Layers Pass

```bash
# Layer 1: Instance running?          ✅
# Layer 2: Has public IP?             ✅ (IP assigned even without DNS)
# Layer 3: IGW attached?              ✅
# Layer 4: Route 0.0.0.0/0 → IGW?    ✅
# Layer 5: Subnet associated to RT?   ✅
# Layer 6: NACL allows port 80?       ✅
# Layer 7: SG allows port 80?         ✅
# Layer 8: Web server running?        ✅
```

---

### Layer 0 — VPC DNS Settings ⬅️ BUG HERE

```bash
# Check if DNS hostnames are enabled on the VPC
aws ec2 describe-vpc-attribute \
  --vpc-id $(terraform output -raw vpc_id) \
  --attribute enableDnsHostnames

# BROKEN state output:
# {
#   "VpcId": "vpc-xxxxxxxx",
#   "EnableDnsHostnames": {
#     "Value": false    ← DNS hostnames disabled
#   }
# }

# Check if DNS support is enabled
aws ec2 describe-vpc-attribute \
  --vpc-id $(terraform output -raw vpc_id) \
  --attribute enableDnsSupport

# Output:
# {
#   "EnableDnsSupport": {
#     "Value": true    ← DNS support is fine
#   }
# }

# Observe the broken output — DNS name is empty
terraform output instance_public_dns    # (empty)
terraform output web_page_url_by_dns   # http:// ← broken!
terraform output web_page_url_by_ip    # http://x.x.x.x/ ← this WORKS
```

---

### Key Observation

In the broken state, accessing via **IP address still works**:
```bash
curl http://$(terraform output -raw instance_public_ip)/
# This SUCCEEDS even in broken state!
```

But accessing via DNS name fails because the name is empty:
```bash
curl http://$(terraform output -raw instance_public_dns)/
# This FAILS — DNS name is empty
```

---

### Fix Options

**Option A — AWS Console:**
1. VPC → Your VPCs → select `brokenlabs-vpc-lab-05-vpc`
2. Actions → Edit VPC settings
3. Enable DNS hostnames → Save

**Option B — AWS CLI:**
```bash
aws ec2 modify-vpc-attribute \
  --vpc-id $(terraform output -raw vpc_id) \
  --enable-dns-hostnames

# Verify
aws ec2 describe-vpc-attribute \
  --vpc-id $(terraform output -raw vpc_id) \
  --attribute enableDnsHostnames
```

**Option C — Deploy fixed Terraform:**
```bash
cd ../fixed
terraform init && terraform apply
```

---

### Verify After Fix

```bash
# DNS name should now be populated
terraform output instance_public_dns
# ec2-x-x-x-x.compute-1.amazonaws.com

# DNS URL should now work
curl -I http://$(terraform output -raw instance_public_dns)/
# HTTP/1.0 200 OK
```
