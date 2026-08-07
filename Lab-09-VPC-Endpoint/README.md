# 🔍 AWS Broken Labs  — VPC Lab 09: VPC Endpoint

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

**Lab 09 of the AWS Broken Labs VPC Series.**

## The Bug
S3 Gateway VPC Endpoint is associated with the **PUBLIC** route table.
Private instance uses the **PRIVATE** route table — no S3 endpoint route there.

## The Fix
Change `route_table_ids` from `[aws_route_table.public.id]` to `[aws_route_table.private.id]`.

## Lab Series
| Lab | Topic | Repo |
|---|---|---|
| Lab 01 | Internet Gateway — missing route | [Lab-01-IGW-Routing](../Lab-01-IGW-Routing/broken/) |
| Lab 02 | Network ACL — rule ordering | [Lab-02-VPC-Network-ACL](../Lab-02-VPC-Network-ACL/broken/) |
| Lab 03 | Security Group — wrong port | [Lab-03-VPC-Security-Group](../Lab-03-VPC-Security-Group/broken/) |
| Lab 04 | Route Table — missing association | [Lab-04-VPC-Route-Table](../Lab-04-VPC-Route-Table/broken/) |
| Lab 05 | VPC Settings — DNS hostnames disabled | [Lab-05-VPC-Settings](../Lab-05-VPC-Settings/broken/) |
| Lab 06 | NAT Gateway — missing entirely | [Lab-06-VPC-Private-Subnets](../Lab-06-VPC-Private-Subnets/broken/) |
| Lab 07 | NAT Gateway — wrong subnet | [Lab-07-VPC-NAT-Gateway](../Lab-07-VPC-NAT-Gateway/broken/) |
| Lab 08 | VPC Peering — missing routes | [Lab-08-VPC-Peering](../Lab-08-VPC-Peering/broken/) |
| **Lab 09** | VPC Endpoint — wrong route table | ⬅️ **You are here** |

## Usage
```bash
# Deploy broken lab
cd broken && terraform init && terraform apply

# Connect and test
aws ssm start-session --target $(terraform output -raw private_instance_id)
aws s3 ls --region us-east-1   # Will FAIL

# Deploy fixed lab
cd ../fixed && terraform init && terraform apply
aws ssm start-session --target $(terraform output -raw private_instance_id)
aws s3 ls --region us-east-1   # Will SUCCEED
```

## Author

**Emmanuel Mulenga** — Multi-Cloud Engineer
- 🌐 [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 [![GitHub Profile](https://img.shields.io/badge/GitHub-e--mulenga-181717?style=flat&logo=github)](https://github.com/e-mulenga)