# 📚 Learning Notes — NAT Gateway & Private Subnets

## Internet Gateway vs NAT Gateway

| Feature | Internet Gateway | NAT Gateway |
|---|---|---|
| **Direction** | Inbound + Outbound | Outbound only |
| **Instance needs** | Public IP | No public IP needed |
| **Placement** | VPC-level | Public subnet |
| **Cost** | Free | ~$0.045/hour + data |
| **Use case** | Public instances | Private instances |

---

## Two-Tier Architecture Pattern

```
┌─────────────────────────────────────────────────┐
│  PUBLIC SUBNET                                  │
│  ├── Internet Gateway route (0.0.0.0/0 → IGW)  │
│  ├── Web servers (have public IPs)              │
│  └── NAT Gateway (has Elastic IP)              │
│            │                                    │
│            │ Masquerades private traffic        │
│            ▼                                    │
├─────────────────────────────────────────────────┤
│  PRIVATE SUBNET                                 │
│  ├── NAT route (0.0.0.0/0 → NAT GW)            │
│  ├── Databases (no public IP)                  │
│  └── App servers (no public IP)                │
└─────────────────────────────────────────────────┘
```

---

## Critical Rule: NAT Gateway Placement

> **The NAT Gateway MUST be in the PUBLIC subnet.**

Common mistake: placing NAT Gateway in the private subnet.
This creates a circular dependency — the private subnet needs the
NAT Gateway to reach the internet, but the NAT Gateway itself
needs internet access via the public subnet's IGW route.

```hcl
resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id  # ← ALWAYS public subnet
}
```

---

## Complete VPC Lab Series

| Lab | Layer | Bug | Fix |
|---|---|---|---|
| **Lab 01** | Routing | Missing IGW route | `aws_route` |
| **Lab 02** | Filtering | NACL DENY before ALLOW | Rule order |
| **Lab 03** | Filtering | SG wrong port (8080) | Port 80 |
| **Lab 04** | Routing | No subnet-RT association | `aws_route_table_association` |
| **Lab 05** | VPC Config | DNS hostnames disabled | `enable_dns_hostnames = true` |
| **Lab 06** | Routing | No NAT GW for private subnet | `aws_nat_gateway` + route |

---

## SSM Session Manager — No SSH Required

This lab uses SSM Session Manager instead of SSH to access the private instance.

Benefits:
- No key pair required
- No SSH port (22) needed in security group
- Works even with no public IP
- Full audit trail in CloudTrail
- No bastion host needed

Required IAM policy: `AmazonSSMManagedInstanceCore`
