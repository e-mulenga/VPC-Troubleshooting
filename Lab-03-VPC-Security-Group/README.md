# 🔍 AWS Broken Labs — VPC Lab 03: Security Group

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 03 of the AWS Broken Labs VPC Series.**
> The VPC, IGW, route table and NACL are all correctly configured —
> but the website still will not load. Your mission: find the Security Group misconfiguration.

---

## 🧭 VPC Lab Series

| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) |
| Lab 02 | Network ACL — rule ordering | [Lab-02-VPC-Network-ACL](../Lab-02-VPC-Network-ACL/broken/) |
| **Lab 03** | Security Group — wrong port | ⬅️ **You are here** |

---

## 🎯 Lab Objective

Everything from Labs 01 and 02 is now **correctly configured**:
- ✅ Internet Gateway attached and routed
- ✅ Route table has `0.0.0.0/0 → IGW`
- ✅ NACL allows inbound port 80
- ✅ Web server running on port 80
- ✅ Instance has a public IP

But the website **still will not load**.

**Your task:** Find the wrong port in the Security Group inbound rules.

---

## 🏗️ Architecture (Broken State)

```
Internet
    │
    ▼
Internet Gateway ✅
    │
    ▼
Route Table: 0.0.0.0/0 → IGW ✅
    │
    ▼
NACL: port 80 allowed ✅
    │
    ▼
┌────────────────────────────────────────┐
│  Security Group (brokenlabs-lab-03-sg) │
│                                        │
│  Inbound Rules:                        │
│  ❌ TCP port 8080 from 0.0.0.0/0      │ ← Wrong port!
│                                        │
│  Missing:                              │
│  ✅ TCP port 80  from 0.0.0.0/0       │ ← Should be this
└────────────────────────────────────────┘
    │
    ▼
EC2 Web Server: running on port 80 ✅
    │
    ▼
Website: ❌ NOT REACHABLE
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

The **Security Group allows port 8080 instead of port 80**.

The web server listens on port **80** (HTTP standard port).
The Security Group inbound rule allows port **8080** (alternative HTTP port).

Traffic arriving on port 80 hits the Security Group and is **implicitly denied**
because there is no matching inbound rule for port 80. Security Groups deny
all traffic by default unless explicitly allowed.

```hcl
# ❌ BROKEN — wrong port
ingress {
  from_port   = 8080   # ← 8080 is not what the web server uses
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

# ✅ FIXED — correct port
ingress {
  from_port   = 80     # ← matches the web server port
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

### The Fix

Change `from_port` and `to_port` from `8080` to `80` in the Security Group
inbound rule — or delete the 8080 rule and add an 80 rule.

</details>

---

## 📁 Project Structure

```
Lab 03 - VPC Security Group/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ Security Group allows port 8080 (wrong)
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ Security Group allows port 80 (correct)
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
# Inspect the Security Group inbound rules to find the bug
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init
terraform plan
terraform apply
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