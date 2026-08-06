# 🔍 AWS Broken Labs — VPC Lab 05: VPC Settings

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 05 of the AWS Broken Labs VPC Series.**
> The VPC, IGW, route table, route table association, NACL, Security Group
> and web server are all correctly configured — but the website still
> will not load. Your mission: find the VPC-level setting that is wrong.


---

## 🧭 VPC Lab Series

| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) | |
| Lab 02 | Network ACL — rule ordering | [Lab-02-VPC-Network-ACL](../Lab-02-VPC-Network-ACL/broken/) |
| Lab 03 | Security Group — wrong port | [Lab-03-VPC-Security-Group](../Lab-03-VPC-Security-Group/broken/) |
| Lab 04 | Route Table — missing association | [Lab-04-VPC-Route-Table](../Lab-04-VPC-Route-Table/broken/) |
| **Lab 05** | VPC Settings — DNS hostnames disabled | ⬅️ **You are here** |

---

## 🎯 Lab Objective

All previous lab bugs are now **correctly fixed**:
- ✅ Internet Gateway attached and routed
- ✅ Route table has `0.0.0.0/0 → IGW`
- ✅ Subnet associated to route table
- ✅ NACL allows port 80
- ✅ Security Group allows port 80
- ✅ Web server running on port 80
- ✅ Instance has a public IP

But the website **still will not load** and the public DNS name is **empty**.

**Your task:** Find the VPC-level DNS setting that prevents hostname resolution.

---

## 🏗️ Architecture (Broken State)

```
Internet
    │
    ▼
Internet Gateway ✅
    │
    ▼
Route Table: 0.0.0.0/0 → IGW ✅  (associated to subnet ✅)
    │
    ▼
NACL: port 80 allowed ✅
    │
    ▼
Security Group: port 80 allowed ✅
    │
    ▼
┌──────────────────────────────────────────────┐
│  VPC (10.0.0.0/16)                           │
│                                              │
│  enable_dns_support   = true  ✅             │
│  enable_dns_hostnames = false ❌ ← THE BUG  │
│                                              │
│  EC2 Instance                                │
│  ├── Public IP: assigned ✅                  │
│  ├── Public DNS name: EMPTY ❌               │
│  └── Web server: running on port 80 ✅       │
└──────────────────────────────────────────────┘
    │
    ▼
Website URL: http:// (empty DNS name) ❌ NOT REACHABLE
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

**`enable_dns_hostnames = false` in the VPC resource.**

When `enable_dns_hostnames` is disabled:
- EC2 instances in the VPC do **not receive public DNS hostnames**
- The `public_dns` attribute on the instance returns an **empty string**
- Any URL built using the DNS name will be empty or broken
- Without a valid hostname, the web page cannot be accessed by DNS name

Note: The instance still has a **public IP** — accessing via IP directly
would work. But the CloudFormation output uses `PublicDnsName` which
returns empty when DNS hostnames are disabled.

```hcl
# ❌ BROKEN
resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = false   # ← THE BUG — must be true
}

# ✅ FIXED
resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true    # ← enables public DNS hostnames
}
```

### The Two DNS Settings Explained

| Setting | Purpose | Required for public DNS? |
|---|---|---|
| `enable_dns_support` | Enables DNS resolution in the VPC | Yes (prerequisite) |
| `enable_dns_hostnames` | Assigns public DNS names to instances | Yes |

Both must be `true` for instances to receive public DNS hostnames.
`enable_dns_support` is a prerequisite — `enable_dns_hostnames` only
works if `enable_dns_support` is also enabled.

</details>

---

## 📁 Project Structure

```
Lab 05 - VPC Settings/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ enable_dns_hostnames = false
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ enable_dns_hostnames = true
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

# Check the output — web_page_url will show http:// (empty DNS name)
# The instance_public_ip will have a value but DNS name will be empty
terraform output web_page_url          # http:// ← empty!
terraform output instance_public_ip   # x.x.x.x ← has value
terraform output instance_public_dns  # (empty)  ← the bug
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init && terraform apply

terraform output web_page_url         # http://ec2-x-x-x-x.compute-1.amazonaws.com/
terraform output instance_public_dns  # ec2-x-x-x-x.compute-1.amazonaws.com
```

---

## 🧹 Teardown

```bash
terraform destroy
```

---

## 👤 Author

**Emmanuel Mulenga** — Multi-Cloud Security Engineer | AWS (6x) | GCP (2x) | Azure (2x) | Terraform | CLLMSP | CLLMSE
- 🌐 LinkedIn: [linkedin.com/in/emmanuel-mulenga](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 GitHub: [github.com/e-mulenga](https://github.com/e-mulenga)