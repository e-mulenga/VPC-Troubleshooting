# 🔍 AWS Broken Labs — VPC Lab 07: NAT Gateway Placement

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 07 of the AWS Broken Labs VPC Series.**
> A NAT Gateway EXISTS this time — but the private instance STILL cannot
> reach the internet. Your mission: find why the NAT Gateway is not working.
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
| **Lab 07** | NAT Gateway — placed in wrong subnet | ⬅️ **You are here** |

---

## 🎯 Lab Objective

Unlike Lab 06, this time a **NAT Gateway does exist**.
The private route table also has a route pointing to it.
But the private instance **still cannot reach the internet**.

**Your task:** Find why a correctly configured NAT Gateway still fails to provide internet access.

---

## 🏗️ Architecture (Broken State)

```
Internet
    │
    ▼
Internet Gateway ✅
    │
    ▼
Public Subnet (10.0.1.0/24)
    └── Route: 0.0.0.0/0 → IGW ✅
    ← NAT Gateway is NOT here ❌

Private Subnet (10.0.2.0/24)
    ├── Route: 0.0.0.0/0 → NAT Gateway ✅ (route exists)
    ├── NAT Gateway ❌ PLACED HERE (WRONG SUBNET!)
    └── Private EC2 Instance
            └── Outbound internet: ❌ FAILS
                (NAT GW in private subnet has no internet route)
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
    └── NAT Gateway ✅ PLACED HERE (CORRECT)

Private Subnet (10.0.2.0/24)
    ├── Route: 0.0.0.0/0 → NAT Gateway ✅
    └── Private EC2 Instance
            └── Outbound internet: ✅ WORKS
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

**The NAT Gateway is placed in the PRIVATE subnet instead of the PUBLIC subnet.**

A NAT Gateway must be placed in a subnet with a route to the Internet Gateway.
The private subnet only has a local route — it cannot reach the internet itself.
A NAT Gateway placed here is effectively isolated — it cannot forward traffic anywhere.

```hcl
# ❌ BROKEN — NAT Gateway in PRIVATE subnet
resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.private.id   # ← WRONG: private subnet
}

# ✅ FIXED — NAT Gateway in PUBLIC subnet
resource "aws_nat_gateway" "lab" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id    # ← CORRECT: public subnet
}
```

### Why This Is a Tricky Bug

- The NAT Gateway **exists** and shows as "available"
- The private route table **has** a route to it
- Everything looks correct at first glance
- The only difference is a single attribute: `subnet_id`

This is a common real-world mistake — especially when copy-pasting
Terraform or CloudFormation code.

</details>

---

## 📁 Project Structure

```
Lab 07 - VPC NAT Gateway/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ NAT GW in private subnet
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ NAT GW in public subnet
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── scripts/
│   └── user_data_private.sh
└── docs/
    ├── troubleshooting.md
    └── learning-notes.md
```

---

## 🚀 Deploy the Broken Lab

```bash
cd broken
terraform init && terraform apply

# Connect via SSM and test
aws ssm start-session --target $(terraform output -raw private_instance_id)
curl -I https://aws.amazon.com   # Will FAIL
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init && terraform apply

aws ssm start-session --target $(terraform output -raw private_instance_id)
curl -I https://aws.amazon.com   # Will SUCCEED
```

> ⚠️ NAT Gateways cost ~$0.045/hour. Run `terraform destroy` when done!

---

## 🧹 Teardown

```bash
terraform destroy
```

---

## 👤 Author

**Emmanuel Mulenga** — Multi-Cloud Security Engineer | AWS (6x) | GCP (6x) | Azure (2x) | Terraform | CLLMSP | CLLMSE
- 🌐 LinkedIn: [linkedin.com/in/emmanuel-mulenga](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 GitHub: [github.com/e-mulenga](https://github.com/e-mulenga)