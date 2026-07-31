# 🔍 AWS Broken Labs — VPC Lab 08: VPC Peering

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 08 of the AWS Broken Labs VPC Series.**
> Two VPCs are peered together — the peering connection is ACTIVE —
> but instances in the two VPCs cannot communicate. Your mission:
> find the missing routes that complete the peering configuration.
>

---

## 🧭 VPC Lab Series

| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) |
| Lab 02 | Network ACL — rule ordering | [Lab-02-VPC-Network-ACL](../Lab-02-VPC-Network-ACL/broken/) |
| Lab 03 | Security Group — wrong port | [Lab-03-VPC-Security-Group](../Lab-03-VPC-Security-Group/broken/) |
| Lab 04 | Route Table — missing association | [Lab-04-VPC-Route-Table](../Lab-04-VPC-Route-Table/broken/) |
| Lab 05 | VPC Settings — DNS hostnames disabled | [Lab-05-VPC-Settings](../Lab-05-VPC-Settings/broken/) | |
| Lab 06 | NAT Gateway — missing entirely | [Lab-06-VPC-Private-Subnets](../Lab-06-VPC-Private-Subnets/broken/) |
| Lab 07 | NAT Gateway — wrong subnet | [Lab-07-VPC-NAT-Gateway](../Lab-07-VPC-NAT-Gateway/broken/) |
| **Lab 08** | VPC Peering — missing routes | ⬅️ **You are here** |

---

## 🎯 Lab Objective

Two VPCs exist with a **peering connection between them**.
The peering connection status is **Active**.

But instances in VPC A and VPC B **cannot communicate with each other**.

**Your task:** Find the two missing routes that complete the VPC peering configuration.

---

## 🏗️ Architecture

### Broken State

```
VPC A (10.0.0.0/16)                    VPC B (10.1.0.0/16)
┌─────────────────────────┐            ┌─────────────────────────┐
│  Subnet A (10.0.1.0/24) │            │  Subnet B (10.1.1.0/24) │
│  EC2 Instance A         │            │  EC2 Instance B         │
│                         │            │                         │
│  Route Table A:         │            │  Route Table B:         │
│  10.0.0.0/16 → local ✅ │            │  10.1.0.0/16 → local ✅ │
│  0.0.0.0/0   → IGW  ✅  │            │  0.0.0.0/0   → IGW  ✅  │
│  10.1.0.0/16 → ???  ❌  │            │  10.0.0.0/16 → ???  ❌  │
│  (MISSING PEERING ROUTE)│            │  (MISSING PEERING ROUTE)│
└─────────┬───────────────┘            └────────────────┬────────┘
          │                                             │
          └──── VPC Peering Connection (ACTIVE) ✅ ─────┘
          │                                             │
          ▼                                             ▼
    Cannot reach B ❌                         Cannot reach A ❌
```

### Fixed State

```
VPC A (10.0.0.0/16)                    VPC B (10.1.0.0/16)
┌─────────────────────────┐            ┌─────────────────────────┐
│  Route Table A:         │            │  Route Table B:         │
│  10.0.0.0/16 → local ✅ │            │  10.1.0.0/16 → local ✅ │
│  0.0.0.0/0   → IGW  ✅  │            │  0.0.0.0/0   → IGW  ✅  │
│  10.1.0.0/16 → pcx  ✅  │            │  10.0.0.0/16 → pcx  ✅  │
└─────────┬───────────────┘            └────────────────┬────────┘
          │                                             │
          └──── VPC Peering Connection (ACTIVE) ✅ ─────┘
          │                                             │
          ▼                                             ▼
    Can reach B ✅                             Can reach A ✅
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

**Both route tables are missing peering routes.**

VPC peering requires routes on BOTH sides:
- VPC A route table needs: `10.1.0.0/16 → peering-connection`
- VPC B route table needs: `10.0.0.0/16 → peering-connection`

Without these routes, traffic between VPCs has no path — even though
the peering connection is active.

```hcl
# ❌ BROKEN — neither route exists

# ✅ FIX — add both routes
resource "aws_route" "vpc_a_to_vpc_b" {
  route_table_id            = aws_route_table.vpc_a.id
  destination_cidr_block    = "10.1.0.0/16"   # VPC B CIDR
  vpc_peering_connection_id = aws_vpc_peering_connection.lab.id
}

resource "aws_route" "vpc_b_to_vpc_a" {
  route_table_id            = aws_route_table.vpc_b.id
  destination_cidr_block    = "10.0.0.0/16"   # VPC A CIDR
  vpc_peering_connection_id = aws_vpc_peering_connection.lab.id
}
```

### The Three Requirements for VPC Peering

1. ✅ VPC Peering Connection — created AND accepted
2. ❌ Route in VPC A pointing to VPC B CIDR via peering connection
3. ❌ Route in VPC B pointing to VPC A CIDR via peering connection

All three must be in place. Missing either route breaks connectivity in that direction.

</details>

---

## 📁 Project Structure

```
Lab 08 - VPC Peering/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ Peering exists but both routes missing
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ Both peering routes added
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── scripts/
│   └── user_data.sh
└── docs/
    ├── troubleshooting.md
    └── learning-notes.md
```

---

## 🚀 Deploy the Broken Lab

```bash
cd broken
terraform init && terraform apply

# Try to ping from Instance A to Instance B's private IP
# Use SSM to connect to Instance A:
aws ssm start-session --target $(terraform output -raw instance_a_id)
ping $(terraform output -raw instance_b_private_ip)  # Will FAIL
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init && terraform apply

aws ssm start-session --target $(terraform output -raw instance_a_id)
ping $(terraform output -raw instance_b_private_ip)  # Will SUCCEED
```

---

## 🧹 Teardown

```bash
terraform destroy
```

---

## 👤 Author

**Emmanuel Mulenga** — Multi-Cloud Security Engineer | AWS (6x) | Terraform | CLLMSP
- LinkedIn: [linkedin.com/in/emmanuel-mulenga](https://www.linkedin.com/in/emmanuel-mulenga)
- GitHub: [github.com/e-mulenga](https://github.com/e-mulenga)