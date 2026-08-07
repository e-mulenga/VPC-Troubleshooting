# 🔍 AWS Broken Labs — VPC Lab 01: Internet Gateway

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

**Lab 01 of the AWS Broken Labs VPC Series.**

> A deliberately broken AWS VPC lab — a web server is deployed with a VPC and Internet Gateway, but the page will not load. Your mission: diagnose and fix the connectivity issue.
>


---

## 🎯 Lab Objective

A web server is running inside a VPC. The EC2 instance has a public IP, an Internet Gateway is attached, and port 80 is open in the security group — but the website is unreachable.

**Your task:** Find and fix the single misconfiguration preventing internet access.

---

## 🏗️ Architecture (Broken State)

```
Internet
    │
    ▼
Internet Gateway (attached to VPC ✅)
    │
    ▼
VPC (10.0.0.0/16)
    │
    ├── Route Table ← ⚠️  MISSING ROUTE TO IGW
    │       │
    │       └── Associated to Public Subnet ✅
    │
    └── Public Subnet (10.0.1.0/24)
            │
            └── EC2 Web Server
                    ├── Public IP: assigned ✅
                    ├── Security Group: port 80 open ✅
                    ├── Web server: running on port 80 ✅
                    └── Page loads: ❌ NOT REACHABLE
```

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug (try to find it yourself first!)</summary>

### Root Cause

The **Route Table has no route to the Internet Gateway**.

A route table is attached to the subnet, but it only has the default local route
(`10.0.0.0/16 → local`). There is no route for internet-bound traffic
(`0.0.0.0/0 → igw-xxxxxxxx`).

Without this route, the subnet behaves like a **private subnet** — traffic
destined for the internet has nowhere to go.

### The Fix

Add the following route to the route table:

```hcl
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}
```

Or in the AWS Console:
1. EC2 → Route Tables → select `brokenlabs-vpc-lab-01-rt`
2. Routes → Edit routes → Add route
3. Destination: `0.0.0.0/0` | Target: Internet Gateway → select `brokenlabs-vpc-lab-01-igw`
4. Save changes → refresh the web page

</details>

---

## 📁 Project Structure

```
Lab 01 - IGW Routing/
├── README.md                   # This file — lab guide
├── .gitignore
├── broken/
│   ├── main.tf                 # ❌ Broken state — missing IGW route
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── fixed/
│   ├── main.tf                 # ✅ Fixed state — IGW route added
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── scripts/
│   └── user_data.sh            # Web server setup script
└── docs/
    ├── troubleshooting.md      # Step-by-step diagnosis guide
    └── learning-notes.md       # VPC connectivity concepts
```

---

## 🚀 Deploy the Broken Lab

```bash
git clone https://github.com/e-mulenga/AWS/VPC Troublshooting/Lab 01 - IGW Routing.git
cd AWS/VPC Troublshooting/Lab 01 - IGW Routing/broken

terraform init
terraform plan
terraform apply

# Note the output — try to access the URL. It will NOT load.
# Your mission: diagnose and fix the issue!
```

---

## ✅ Deploy the Fixed Version

```bash
cd ../fixed
terraform init
terraform plan
terraform apply

# The web page should now load successfully
```

---

## 🔍 Troubleshooting Methodology

When a web server is unreachable, work through these layers in order:

```
Layer 1 — Is the instance running?
  aws ec2 describe-instances --instance-ids <id> --query "Reservations[].Instances[].State.Name"

Layer 2 — Does the instance have a public IP?
  terraform output instance_public_ip

Layer 3 — Is the security group correct?
  Check: port 80 inbound from 0.0.0.0/0

Layer 4 — Is the subnet associated to a route table?
  Check: Subnet → Route Table association

Layer 5 — Does the route table have a route to the IGW?
  Check: 0.0.0.0/0 → igw-xxxxxxxx  ← THIS IS THE BUG

Layer 6 — Is the IGW attached to the VPC?
  Check: VPC → Internet Gateways

Layer 7 — Is the web server actually running?
  aws ec2-instance-connect send-ssh-public-key ... (or SSM Session Manager)
  systemctl status lab-web
```

---

## 📚 Key AWS Concepts Demonstrated

| Concept | What You Learn |
|---|---|
| **VPC Route Tables** | How traffic routing works in AWS |
| **Internet Gateway** | Attaching vs routing — two separate steps |
| **Public vs Private Subnet** | The route table is what makes a subnet "public" |
| **Security Groups** | Stateful firewall at the instance level |
| **EC2 User Data** | Bootstrap scripts run at launch |
| **Systematic Troubleshooting** | Layer-by-layer diagnosis methodology |

---

## 💡 Key Insight

> **Attaching an Internet Gateway to a VPC is NOT enough.**
> You must ALSO add a route (`0.0.0.0/0 → igw`) in the route table.
> Without the route, the subnet remains effectively private regardless of the IGW attachment.

---

## 🧹 Teardown

```bash
cd broken/  # or fixed/
terraform destroy
```

---

## 👤 Author

**Emmanuel Mulenga** — Multi-Cloud Engineer
- 🌐 [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 [![GitHub Profile](https://img.shields.io/badge/GitHub-e--mulenga-181717?style=flat&logo=github)](https://github.com/e-mulenga)