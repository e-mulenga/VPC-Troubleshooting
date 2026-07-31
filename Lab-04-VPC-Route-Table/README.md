# 🔍 AWS Broken Labs — VPC Lab 04: Route Table Association

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 04 of the AWS Broken Labs VPC Series.**
> The VPC, IGW, route table with IGW route, Security Group and web server
> are all correctly configured — but the website still will not load.
> Your mission: find the missing association.
>

---

## 🧭 VPC Lab Series

| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) | |
| Lab 02 | Network ACL — rule ordering | [Lab-02-VPC-Network-ACL](../Lab-02-VPC-Network-ACL/broken/) |
| Lab 03 | Security Group — wrong port | [Lab-03-VPC-Security-Group](../Lab-03-VPC-Security-Group/broken/) |
| **Lab 04** | Route Table — missing association | ⬅️ **You are here** |

---

## 🎯 Lab Objective

All previous lab bugs are now **correctly fixed**:
- ✅ Internet Gateway attached to VPC
- ✅ Route table EXISTS with `0.0.0.0/0 → IGW`
- ✅ Security Group allows port 80
- ✅ NACL allows port 80
- ✅ Web server running on port 80
- ✅ Instance has a public IP

But the website **still will not load**.

**Your task:** Find the missing link between the subnet and the route table.

---

## 🏗️ Architecture (Broken State)

```
Internet
    │
    ▼
Internet Gateway ✅
    │
    ▼
┌─────────────────────────────────────────────────┐
│  VPC (10.0.0.0/16)                              │
│                                                 │
│  LabRouteTable ✅                               │
│  └── Route: 0.0.0.0/0 → IGW ✅                 │
│  └── Subnet association: ❌ MISSING             │
│                                                 │
│  Default Route Table (auto-created by AWS)      │
│  └── Route: 10.0.0.0/16 → local only           │
│  └── LabSubnet is using THIS one ← the bug     │
│                                                 │
│  LabSubnet (10.0.1.0/24)                       │
│  └── Associated to: Default RT (no IGW route)  │
│  └── Should be:     LabRouteTable              │
│                                                 │
│  EC2 Web Server ✅                              │
└─────────────────────────────────────────────────┘
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

The **subnet is not associated to the custom route table**.

A custom route table (`LabRouteTable`) exists with the correct IGW route.
But the subnet was never associated to it — so it falls back to the
**VPC default route table**, which only has the local route and no IGW route.

```hcl
# ❌ BROKEN — this resource is MISSING entirely
# aws_route_table_association is never created
# Subnet uses VPC default route table (no IGW route)

# ✅ THE FIX — add this resource
resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}
```

### Why This Is Subtle

This bug is easy to miss because:
1. The route table **exists** and has the correct route
2. The IGW **is attached** to the VPC
3. Everything **looks right** in isolation
4. The missing link is the **association** — an easy oversight

</details>

---

## 📁 Project Structure

```
Lab 04 - VPC Route Table/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ aws_route_table_association missing
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ aws_route_table_association added
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
terraform init
terraform plan
terraform apply

# Try the URL from outputs — it will NOT load
# Inspect which route table the subnet is associated to
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init && terraform apply
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