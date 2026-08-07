# AWS Broken Labs — VPC Lab 10: Network ACL Outbound Ephemeral Ports

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com)
[![Lab](https://img.shields.io/badge/Type-Broken_Lab-red?style=for-the-badge)]()
[![Series](https://img.shields.io/badge/Series-VPC_Labs-blue?style=for-the-badge)]()

> **Lab 10 of the AWS Broken Labs VPC Series.**
> IGW, route table, subnet association and Security Group are all correct —
> but the web page still won't load. The NACL outbound rule only permits
> port 80, blocking ephemeral port return traffic. Your mission: fix the
> stateless NACL outbound rules.
>

---

## 🧭 Complete VPC Lab Series

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
| Lab 09 | VPC Endpoint — wrong route table | [Lab-09-VPC-Endpoint](../Lab-09-VPC-Endpoint/broken/) |
| **Lab 10** | **NACL — outbound ephemeral ports** | ⬅️ **You are here** |

---

## 🎯 Lab Objective

All previous bugs are fixed:
- ✅ IGW attached and routed
- ✅ Subnet associated to route table
- ✅ Security Group allows port 80
- ✅ NACL inbound allows port 80
- ✅ Web server running

But the browser **hangs or times out**. The request seems to reach the server
but the page never loads.

**Your task:** Find why the NACL outbound rules block the server's response.

---

## 🐛 The Bug

<details>
<summary>⚠️  Click to reveal the bug</summary>

### Root Cause

**The NACL outbound rule only allows port 80 — blocking ephemeral port return traffic.**

NACLs are **stateless**. When a browser connects to the server:
- Request: client ephemeral port → server port 80 (inbound — allowed ✅)
- Response: server port 80 → client ephemeral port (outbound — **BLOCKED** ❌)

The server's HTTP response is destined for the client's random ephemeral port
(e.g. 54321), not port 80. Since the outbound NACL rule only allows port 80,
the response is silently dropped.

```hcl
# ❌ BROKEN — only port 80 outbound
resource "aws_network_acl_rule" "outbound_http_only" {
  rule_number = 100
  from_port   = 80
  to_port     = 80    # Ephemeral ports NOT allowed
  egress      = true
}

# ✅ FIXED — add ephemeral port range outbound
resource "aws_network_acl_rule" "outbound_ephemeral" {
  rule_number = 110
  from_port   = 1024
  to_port     = 65535
  egress      = true
}
```

</details>

---

## 🚀 Deploy

```bash
# Broken
cd broken && terraform init && terraform apply
curl -I --max-time 5 http://$(terraform output -raw instance_public_ip)/
# Will hang or timeout

# Fixed
cd ../fixed && terraform init && terraform apply
curl -I http://$(terraform output -raw instance_public_ip)/
# HTTP/1.0 200 OK
```

## 🧹 Teardown

```bash
terraform destroy
```

---

## 👤 Author

**Emmanuel Mulenga** — Multi-Cloud Engineer
- 🌐 [![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/emmanuel-mulenga)
- 💻 [![GitHub Profile](https://img.shields.io/badge/GitHub-e--mulenga-181717?style=flat&logo=github)](https://github.com/e-mulenga)