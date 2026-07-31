# 📚 Learning Notes — Route Table Associations

## The VPC Default Route Table

Every VPC comes with a **main (default) route table** created automatically by AWS.

```
Default Route Table:
└── Route: 10.0.0.0/16 → local   (the VPC CIDR — intra-VPC traffic)
└── NO internet route
```

Any subnet **not explicitly associated** to a custom route table
automatically uses this default route table.

---

## The Association Gap

This is the key insight from Lab 04:

```
You can have:  IGW attached to VPC          ✅
You can have:  Route table with IGW route   ✅
You can have:  Subnet in the same VPC       ✅

But if the subnet is not ASSOCIATED to the route table:
  → Subnet uses the default RT
  → Default RT has no IGW route
  → No internet access
```

**Having a route table does not automatically make subnets use it.**
The association is always a separate, explicit step.

---

## Lab Series — Full Summary

| Lab | Missing Element | Terraform Resource |
|---|---|---|
| **Lab 01** | IGW route in route table | `aws_route` |
| **Lab 02** | NACL ALLOW before DENY | `aws_network_acl_rule` order |
| **Lab 03** | Correct port in SG (80 not 8080) | `aws_security_group` ingress port |
| **Lab 04** | Subnet association to route table | `aws_route_table_association` |

---

## Systematic Troubleshooting — Complete 8-Layer Model

```
Layer 1: Is the instance running?
Layer 2: Does it have a public IP / Elastic IP?
Layer 3: Is the Internet Gateway attached to the VPC?
Layer 4: Does the route table have 0.0.0.0/0 → IGW?
Layer 5: Is the subnet ASSOCIATED to that route table?   ← Lab 04
Layer 6: Does the NACL allow the traffic (correct port, no DENY first)?
Layer 7: Does the Security Group allow the correct port?
Layer 8: Is the application actually running and listening?
```

Note: Layers 4 and 5 are closely related — a route table is useless
if no subnet is associated to it.

---

## Terraform Best Practice

Always declare the association explicitly and immediately after the route table:

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Always follow with the association — easy to forget!
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```
