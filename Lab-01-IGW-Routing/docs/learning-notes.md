# 📚 Learning Notes — VPC Internet Connectivity

## Key Concept: What Makes a Subnet "Public"?

A subnet is only public if ALL of the following are true:

| Requirement | Check |
|---|---|
| VPC has an Internet Gateway attached | `aws ec2 describe-internet-gateways` |
| Route table has `0.0.0.0/0 → igw-xxx` | `aws ec2 describe-route-tables` |
| Route table is associated to the subnet | Check subnet associations |
| Instance has a public IP or Elastic IP | `aws ec2 describe-instances` |
| Security group allows inbound traffic | Check ingress rules |

**Missing any one of these = no internet access.**

---

## The Two-Step IGW Mistake

Many engineers confuse these two separate steps:

```
Step 1: ATTACH the Internet Gateway to the VPC
  aws ec2 attach-internet-gateway --vpc-id vpc-xxx --internet-gateway-id igw-xxx
  ✅ Done — but traffic still cannot reach the internet!

Step 2: ADD a ROUTE in the route table pointing to the IGW
  Destination: 0.0.0.0/0
  Target: igw-xxx
  ✅ NOW internet traffic can flow
```

**This lab deliberately omits Step 2 to teach this distinction.**

---

## VPC Traffic Flow (Fixed State)

```
EC2 Instance (10.0.1.x)
       │
       │ Outbound packet to 8.8.8.8
       ▼
Route Table lookup:
  10.0.0.0/16 → local    (not a match)
  0.0.0.0/0   → igw-xxx  ← MATCHES — send to IGW
       │
       ▼
Internet Gateway
       │
       ▼
Internet (8.8.8.8)
```

```
EC2 Instance (10.0.1.x)
       ▲
       │ Inbound packet from internet user
Internet Gateway
       │
Route Table lookup confirms subnet is associated
       │
Security Group check: port 80 allowed ✅
       │
       ▼
EC2 Instance receives the request
```

---

## Terraform vs CloudFormation

This lab was originally written in CloudFormation. The Terraform conversion
demonstrates an important difference:

**CloudFormation:**
```yaml
LabRouteTable:
  Type: AWS::EC2::RouteTable
  # No Route resource defined = missing IGW route (the bug)
```

**Terraform (broken):**
```hcl
resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  # No inline route or aws_route resource = missing IGW route
}
```

**Terraform (fixed):**
```hcl
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.lab.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab.id
}
```

The fix is identical in both IaC tools — one missing resource.
