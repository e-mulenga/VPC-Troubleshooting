# Troubleshooting — VPC Lab 10

## Layers 1-9 all pass (Labs 01-09 bugs fixed).
## Bug is in NACL outbound rules.

```bash
# Check outbound NACL rules
aws ec2 describe-network-acls \
  --network-acl-ids $(terraform output -raw nacl_id) \
  --query "NetworkAcls[].Entries[?Egress==\`true\`]"

# BROKEN state:
# [{ "RuleNumber": 100, "Protocol": "6", "RuleAction": "allow",
#    "PortRange": {"From": 80, "To": 80} }]
# ← Only port 80 outbound — ephemeral ports NOT allowed!

# FIXED state:
# [
#   { "RuleNumber": 100, "PortRange": {"From": 80, "To": 80} },
#   { "RuleNumber": 110, "PortRange": {"From": 1024, "To": 65535} }
# ]
```

## Why the page hangs/times out

1. Browser connects to server on port 80 from a random source port (e.g. 54321)
2. Server receives the request — inbound rule allows port 80 ✅
3. Server tries to respond FROM port 80 TO the browser's port 54321
4. This is OUTBOUND traffic on port 54321 (not 80!)
5. NACL outbound rule only allows port 80 outbound
6. Response is BLOCKED — browser sees a timeout/hang

## Fix

```bash
aws ec2 create-network-acl-entry \
  --network-acl-id $(terraform output -raw nacl_id) \
  --rule-number 110 \
  --protocol tcp \
  --rule-action allow \
  --egress \
  --cidr-block 0.0.0.0/0 \
  --port-range From=1024,To=65535
```

Or deploy the fixed Terraform config:
```bash
cd ../fixed && terraform init && terraform apply
```
