# 🔍 AWS Broken Labs — VPC Lab 06: NAT Gateway

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 06 of the AWS Broken Labs VPC Series.**
> A private EC2 instance needs to download packages from the internet
> but has no outbound internet connectivity. Your mission: find and fix
> the missing NAT Gateway configuration.


---

## 🧭 VPC Lab Series

| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) |
| Lab 02 | Network ACL — rule ordering | [Lab-02-VPC-Network-ACL](../Lab-02-VPC-Network-ACL/broken/) |
| Lab 03 | Security Group — wrong port | [Lab-03-VPC-Security-Group](../Lab-03-VPC-Security-Group/broken/) |
| Lab 04 | Route Table — missing association | [Lab-04-VPC-Route-Table](../Lab-04-VPC-Route-Table/broken/) |
| Lab 05 | VPC Settings — DNS hostnames disabled | [Lab-05-VPC-Settings](../Lab-05-VPC-Settings/broken/) |
| **Lab 06** | NAT Gateway — missing for private subnet | ⬅️ **You are here** |

---

## 🎯 Lab Objective

This lab introduces a **two-tier architecture** — public and private subnets.

A private EC2 instance needs outbound internet access to download packages,
but it must NOT be directly accessible from the internet.

The architecture is partially built — but the private instance cannot
reach the internet. Your task: identify and fix the missing component.

**Question:** How does a private instance access the internet without
having a public IP or being directly exposed to the internet?

---

## 🏗️ Architecture

### Broken State

```
Internet
    │
    ▼
Internet Gateway ✅
    │
    ▼
Public Subnet (10.0.1.0/24)
    ├── Route: 0.0.0.0/0 → IGW ✅
    ├── Bastion Host (optional) ✅
    └── NAT Gateway: ❌ MISSING

Private Subnet (10.0.2.0/24)
    ├── Route: 0.0.0.0/0 → ??? ❌ NO ROUTE TO INTERNET
    └── Private EC2 Instance
            ├── No public IP ✅ (correct for private)
            ├── SSM access works ✅ (via VPC endpoints)
            └── Outbound internet: ❌ CANNOT REACH INTERNET
```

### Fixed State

```
Internet
    │
    ▼
Internet Gateway ✅
    │
    ▼
Public Subnet (10.0.1.0/24)
    ├── Route: 0.0.0.0/0 → IGW ✅
    └── NAT Gateway + Elastic IP ✅

Private Subnet (10.0.2.0/24)
    ├── Route: 0.0.0.0/0 → NAT Gateway ✅
    └── Private EC2 Instance
            ├── No public IP ✅ (still private — not exposed)
            ├── SSM access works ✅
            └── Outbound internet: ✅ VIA NAT GATEWAY
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

**The NAT Gateway is never created and the private route table has no route to the internet.**

Two things are missing:
1. `aws_nat_gateway` resource (and `aws_eip` for it)
2. `aws_route` on the private route table pointing to the NAT Gateway

```hcl
# ❌ BROKEN — neither of these resources exist

# Missing 1: NAT Gateway + Elastic IP
resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id  # NAT GW must be in PUBLIC subnet
}

# Missing 2: Private route to NAT Gateway
resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.lab.id
}
```

### Key Concept

| Component | Lives in | Traffic direction |
|---|---|---|
| Internet Gateway | VPC (not subnet-specific) | Inbound + Outbound (public) |
| NAT Gateway | **Public subnet** | Outbound only (for private instances) |
| Private instance | Private subnet | Outbound via NAT, no inbound from internet |

</details>

---

## 📁 Project Structure

```
Lab 06 - VPC NAT Gateway/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ No NAT GW, no private internet route
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ NAT GW + Elastic IP + private route added
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── scripts/
│   ├── user_data_public.sh    # Public bastion bootstrap
│   └── user_data_private.sh   # Private instance bootstrap
└── docs/
    ├── troubleshooting.md
    └── learning-notes.md
```

---

## 🚀 Deploy the Broken Lab

```bash
cd broken
terraform init && terraform plan && terraform apply

# Test outbound connectivity from private instance via SSM
aws ssm start-session --target $(terraform output -raw private_instance_id)
# Once connected:
curl -I https://aws.amazon.com  # Will FAIL — no internet route
ping 8.8.8.8                    # Will FAIL — no route
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init && terraform apply

# Test outbound connectivity
aws ssm start-session --target $(terraform output -raw private_instance_id)
curl -I https://aws.amazon.com  # Will SUCCEED via NAT Gateway
```

> **Note:** The NAT Gateway takes 1-2 minutes to become available after creation.

---

## 💰 Cost Note

NAT Gateways are **not free tier eligible** and cost approximately:
- $0.045/hour (~$32/month)
- Plus $0.045/GB data processed

**Remember to run `terraform destroy` after completing the lab!**

---

## 🧹 Teardown

```bash
terraform destroy
```

---

## 👤 Author

**Emmanuel Mulenga** — Multi-Cloud Engineer
- 🌐 [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 [![GitHub Profile](https://img.shields.io/badge/GitHub-e--mulenga-181717?style=flat&logo=github)](https://github.com/e-mulenga)