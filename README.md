# VPC Troubleshooting Labs

Hands-on troubleshooting labs for Amazon VPC networking.

## Why These Labs

VPC connectivity issues are one of the most common — and most frustrating — categories of AWS incidents. A web server that "should just work" but doesn't reach the internet, a private instance that can't reach S3, two peered VPCs that still can't talk to each other. The root cause is almost always a single misconfigured resource buried in a much larger, otherwise-correct setup.

These labs reproduce those exact scenarios. Each lab deploys a realistic but broken VPC environment using Terraform. Your job is to diagnose the problem using the AWS CLI/Console, identify the root cause, and apply the fix — the same layered, methodical approach you'd use in a production environment.

Each lab follows a consistent structure:
- **`broken/`** — the intentionally broken Terraform configuration
- **`fixed/`** — the corrected configuration
- **`docs/`** — a troubleshooting guide (step-by-step diagnosis) and learning notes (the underlying concept)

## Labs

| # | Lab | Concept | Difficulty |
|---|---|---|---|
| 01 | [Lab 01 — Internet Gateway](./Lab-01-IGW-Routing/) | Route table missing the IGW route | Beginner |
| 02 | [Lab 02 — Network ACL](./Lab-02-VPC-Network-ACL/) | NACL DENY rule evaluated before ALLOW | Beginner |
| 03 | [Lab 03 - VPC Security Group](./Lab-03-VPC-Security-Group/) | Security group open on the wrong port (8080 vs 80) | Beginner |
| 04 | [Lab 04 - VPC Route Table](./Lab-04-VPC-Route-Table/) | Subnet never associated with its route table | Beginner |
| 05 | [Lab 05 - VPC Settings](./Lab-05-VPC-Settings/) | VPC DNS hostnames disabled | Beginner |
| 06 | [Lab 06 - VPC NAT Gateway](./Lab-06-VPC-Private-Subnets/) | No NAT Gateway for a private subnet | Intermediate |
| 07 | [Lab 07 - VPC NAT Gateway](./Lab-07-VPC-NAT-Gateway/) | NAT Gateway placed in the private subnet, not public | Intermediate |
| 08 | [Lab 08 - VPC Peering](./Lab-08-VPC-Peering/) | Peering connection active, but routes missing on both sides | Intermediate |
| 09 | [Lab 09 - VPC Endpoint](./Lab-09-VPC-Endpoint/) | S3 Gateway Endpoint associated with the wrong route table | Intermediate |
| 10 | [Lab 10 - Network ACL](./Lab-10-Network-ACL) | NACL outbound rule missing ephemeral port range | Intermediate |

## Prerequisites

- An AWS account with access to the AWS Console and CLI
- Terraform >= 1.5.0
- Basic familiarity with VPC concepts (subnets, route tables, gateways, security groups, NACLs)
- AWS Systems Manager Session Manager plugin installed (required for Labs 06–09, which use private instances with no public IP)

## How to Use Each Lab

```bash
# Deploy the broken environment
cd "Lab XX - <name>/broken"
terraform init
terraform apply

# Diagnose using the lab's docs/troubleshooting.md
# Try to identify the root cause yourself before checking the README's
# hidden "The Bug" section

# Deploy the fixed environment to confirm the resolution
cd ../fixed
terraform init
terraform apply

# Always clean up when done
terraform destroy
```

## Cleanup

After completing a lab, destroy the Terraform stack to avoid ongoing charges:

```bash
terraform destroy
```

> Labs 06 and 07 create a NAT Gateway, which incurs an hourly charge
> (~$0.045/hour) plus data processing — remember to destroy these
> promptly after use.

## Author

**Emmanuel Mulenga** — Multi-Cloud Engineer
- 🌐 [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 [![GitHub Profile](https://img.shields.io/badge/GitHub-e--mulenga-181717?style=flat&logo=github)](https://github.com/e-mulenga)