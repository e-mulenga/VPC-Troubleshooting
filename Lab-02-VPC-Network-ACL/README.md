# 🔍 AWS Broken Labs — VPC Lab 02: Network ACL

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 02 of the AWS Broken Labs VPC Series.**
> The VPC, IGW, route table and security group are all correctly configured — but the website still won't load. Your mission: diagnose and fix the Network ACL misconfiguration.
>

---

## 🧭 VPC Lab Series

| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) |
| **Lab 02** | Network ACL — rule ordering | ⬅️ **You are here** |

---

## 🎯 Lab Objective

Everything that was broken in Lab 01 is now **correctly configured**:
- ✅ Internet Gateway attached to VPC
- ✅ Route table has `0.0.0.0/0 → IGW`
- ✅ Subnet associated to route table
- ✅ Security group allows port 80
- ✅ Web server running

But the website **still will not load**. Something else is blocking traffic.

**Your task:** Find the misconfiguration in the Network ACL that prevents HTTP access.

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
┌─────────────────────────────────────┐
│  Network ACL (brokenlabs-nacl)      │
│                                     │
│  Inbound Rules:                     │
│  Rule 90  — DENY  TCP port 80 ❌   │ ← evaluated FIRST
│  Rule 100 — ALLOW TCP port 80 ✅   │ ← never reached
│                                     │
│  Outbound Rules:                    │
│  Rule 100 — ALLOW ALL ✅            │
└─────────────────────────────────────┘
    │
    ▼
Public Subnet (10.0.1.0/24)
    │
    ▼
Security Group: port 80 open ✅
    │
    ▼
EC2 Web Server: running ✅
    │
    ▼
Website: ❌ NOT REACHABLE
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

**Network ACL Rule 90 DENIES port 80 before Rule 100 can ALLOW it.**

NACLs process rules in **ascending numerical order** — lowest rule number first.
The first matching rule wins. All subsequent rules are ignored.

```
Inbound traffic on port 80:

Rule 90  → DENY port 80  ← MATCHES FIRST → traffic BLOCKED ❌
Rule 100 → ALLOW port 80 ← NEVER REACHED
```

### The Fix

**Option A** — Delete the DENY rule (Rule 90):
```hcl
# Remove this rule entirely from the broken configuration
# aws_network_acl_rule "inbound_deny_http"
```

**Option B** — Change the DENY rule number to be HIGHER than the ALLOW rule:
```hcl
resource "aws_network_acl_rule" "inbound_deny_http" {
  rule_number = 110  # Changed from 90 to 110 — now evaluated AFTER the allow rule
  ...
}
```

**The fixed version removes the DENY rule entirely** — there is no valid
reason to have a DENY before an ALLOW for the same port.

</details>

---

## 📁 Project Structure

```
aws/VPC Troublshooting/Lab 02 - VPC Network ACL/
├── README.md
├── .gitignore
├── broken/
│   ├── main.tf          # ❌ NACL Rule 90 DENY before Rule 100 ALLOW
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf          # ✅ DENY rule removed — port 80 ALLOW only
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── scripts/
│   └── user_data.sh     # Web server bootstrap
└── docs/
    ├── troubleshooting.md
    └── learning-notes.md
```

---

## 🚀 Deploy the Broken Lab

```bash
git clone https://github.com/e-mulenga/aws/VPC Troublshooting/Lab 02 - VPC Network ACL.git
cd aws/VPC Troublshooting/Lab 02 - VPC Network ACL/broken

terraform init
terraform plan
terraform apply

# Try the URL from outputs — it will NOT load
# Diagnose the NACL rules to find the bug
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init
terraform plan
terraform apply

# The web page now loads successfully
```

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
