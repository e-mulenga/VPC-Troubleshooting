# 📚 Learning Notes — VPC DNS Settings

## The Two VPC DNS Settings

| Setting | Terraform Attribute | Purpose |
|---|---|---|
| DNS Resolution | `enable_dns_support` | Allows instances to use AWS DNS resolver (169.254.169.253) |
| DNS Hostnames | `enable_dns_hostnames` | Assigns public DNS names to instances with public IPs |

---

## How They Work Together

```
enable_dns_support = true  (prerequisite — must be true first)
         +
enable_dns_hostnames = true
         =
EC2 instance gets: ec2-x-x-x-x.compute-1.amazonaws.com
```

```
enable_dns_support = true
         +
enable_dns_hostnames = false  ← Lab 05 bug
         =
EC2 instance gets: (no public DNS name — empty string)
```

---

## Default Values by VPC Type

| VPC Type | enable_dns_support | enable_dns_hostnames |
|---|---|---|
| Default VPC (AWS-created) | true | true |
| Custom VPC (user-created) | true | **false** ← common gotcha |

This is the sneaky part — custom VPCs default to
`enable_dns_hostnames = false`. You must explicitly set it to `true`.

---

## Terraform Best Practice

Always explicitly set both DNS attributes in custom VPCs:

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true   # Always true — enables DNS resolver
  enable_dns_hostnames = true   # Always true — enables public DNS names
}
```

---

## Complete VPC Lab Series — All Bugs Summarised

| Lab | Layer | Bug | Missing Resource / Setting |
|---|---|---|---|
| **Lab 01** | Routing | Missing IGW route | `aws_route` |
| **Lab 02** | Filtering | NACL DENY before ALLOW | `aws_network_acl_rule` order |
| **Lab 03** | Filtering | SG wrong port (8080 vs 80) | `ingress.from_port / to_port` |
| **Lab 04** | Routing | Subnet not associated to RT | `aws_route_table_association` |
| **Lab 05** | VPC Config | DNS hostnames disabled | `enable_dns_hostnames = true` |

---

## Full 8-Layer Troubleshooting Model (Updated)

```
Layer 0: VPC Settings — DNS support and hostnames enabled?   ← Lab 05
Layer 1: Is the instance running?
Layer 2: Does it have a public IP / Elastic IP?
Layer 3: Is the Internet Gateway attached to the VPC?
Layer 4: Does the route table have 0.0.0.0/0 → IGW?         ← Lab 01
Layer 5: Is the subnet associated to that route table?       ← Lab 04
Layer 6: Does the NACL allow the traffic?                    ← Lab 02
Layer 7: Does the Security Group allow the correct port?     ← Lab 03
Layer 8: Is the application running and listening?
```
