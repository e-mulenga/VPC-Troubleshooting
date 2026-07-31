# 🔍 Troubleshooting Guide — VPC Lab 02

## Diagnosis Checklist

If you completed Lab 01 first, use the same layered approach.
The first 5 layers will all pass — the bug is in Layer 6.

---

### Layer 1–5 — All Pass (same as Lab 01)

```bash
# Layer 1: Instance running?
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id) \
  --query "Reservations[].Instances[].State.Name" --output text
# ✅ running

# Layer 2: Has public IP?
terraform output instance_public_ip
# ✅ has IP

# Layer 3: Security group allows port 80?
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=brokenlabs-vpc-lab-02-sg" \
  --query "SecurityGroups[].IpPermissions"
# ✅ port 80 open

# Layer 4: Route table associated to subnet?
# ✅ yes

# Layer 5: Route table has 0.0.0.0/0 → IGW?
# ✅ yes (fixed from Lab 01)
```

---

### Layer 6 — Network ACL Rules ⬅️ BUG HERE

```bash
# Inspect NACL rules
aws ec2 describe-network-acls \
  --network-acl-ids $(terraform output -raw nacl_id) \
  --query "NetworkAcls[].Entries[?Egress==\`false\`] | [] | sort_by(@, &RuleNumber)"

# What you see in BROKEN state:
# Rule 90  — DENY  — TCP — port 80 — 0.0.0.0/0  ← MATCHES FIRST ❌
# Rule 100 — ALLOW — TCP — port 80 — 0.0.0.0/0  ← NEVER REACHED

# What you expect in FIXED state:
# Rule 100 — ALLOW — TCP — port 80 — 0.0.0.0/0  ← MATCHES ✅
# Rule 200 — ALLOW — TCP — ports 1024-65535      ← Ephemeral return traffic
```

---

### Fix Options

**Option A — Delete the DENY rule (recommended):**
```bash
aws ec2 delete-network-acl-entry \
  --network-acl-id $(terraform output -raw nacl_id) \
  --rule-number 90 \
  --ingress
```

**Option B — Change the DENY rule number to higher than ALLOW:**
```bash
# In AWS Console:
# NACL → Inbound rules → Edit → change Rule 90 to Rule 110
```

**Option C — Deploy the fixed Terraform config:**
```bash
cd ../fixed
terraform init && terraform apply
```
