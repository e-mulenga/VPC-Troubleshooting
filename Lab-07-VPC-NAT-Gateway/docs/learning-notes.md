# 📚 Learning Notes — NAT Gateway Placement

## The Golden Rule

> **NAT Gateway MUST always be placed in a PUBLIC subnet.**

A public subnet is one with a route to an Internet Gateway.
The NAT Gateway needs this to forward traffic to the internet.

---

## Lab 06 vs Lab 07 Comparison

| | Lab 06 | Lab 07 |
|---|---|---|
| NAT Gateway exists? | ❌ No | ✅ Yes |
| NAT Gateway state | N/A | Available |
| Private route to NAT GW? | ❌ No | ✅ Yes |
| NAT GW subnet | N/A | ❌ Private (wrong) |
| Result | No internet | No internet |
| Fix | Create NAT GW in PUBLIC | Move NAT GW to PUBLIC |

Both labs result in the same symptom — different root causes.

---

## Traffic Flow (Fixed)

```
Private Instance (10.0.2.x)
    │ Outbound packet to 8.8.8.8
    ▼
Private Route Table
    └── 0.0.0.0/0 → nat-xxx
    ▼
NAT Gateway (in PUBLIC subnet, has Elastic IP)
    └── Translates source IP: 10.0.2.x → EIP
    ▼
Public Route Table
    └── 0.0.0.0/0 → igw-xxx
    ▼
Internet Gateway → Internet

Return traffic follows the same path in reverse.
The private instance IP is never exposed.
```

---

## Why You Cannot Move a NAT Gateway

Unlike route table associations or security group rules,
a NAT Gateway's subnet cannot be changed after creation.
To fix incorrect placement you must:
1. Delete the misplaced NAT Gateway
2. Create a new NAT Gateway in the correct subnet
3. Update route table entries to point to the new NAT Gateway

Terraform handles this automatically when you change `subnet_id`.

---

## Complete VPC Lab Series Summary

| Lab | Bug | One-Line Fix |
|---|---|---|
| **Lab 01** | Missing IGW route | Add `aws_route` with `gateway_id = IGW` |
| **Lab 02** | NACL DENY before ALLOW | Remove DENY rule or raise rule number |
| **Lab 03** | SG port 8080 vs 80 | Change `from_port/to_port` to 80 |
| **Lab 04** | No subnet-RT association | Add `aws_route_table_association` |
| **Lab 05** | DNS hostnames disabled | Set `enable_dns_hostnames = true` |
| **Lab 06** | No NAT Gateway | Add `aws_nat_gateway` + private route |
| **Lab 07** | NAT GW in private subnet | Change `subnet_id` to public subnet |
