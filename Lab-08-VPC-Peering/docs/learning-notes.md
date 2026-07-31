# 📚 Learning Notes — VPC Peering

## Three Requirements for VPC Peering

```
1. VPC Peering Connection — must be created AND accepted
   aws_vpc_peering_connection { auto_accept = true }  # same account/region

2. Route in VPC A → VPC B CIDR via peering connection
   destination: 10.1.0.0/16 → pcx-xxx

3. Route in VPC B → VPC A CIDR via peering connection
   destination: 10.0.0.0/16 → pcx-xxx
```

Missing ANY one of these breaks connectivity.

---

## VPC Peering Limitations

| Limitation | Detail |
|---|---|
| **No transitive routing** | A→B and B→C does NOT mean A→C |
| **Non-overlapping CIDRs** | VPC CIDRs must not overlap |
| **No edge-to-edge routing** | Cannot route through IGW, NAT GW or VPN via peering |
| **One peering per VPC pair** | Only one peering connection between two VPCs |

---

## Complete VPC Lab Series Summary

| Lab | Bug | Fix |
|---|---|---|
| **Lab 01** | Missing IGW route | `aws_route` → IGW |
| **Lab 02** | NACL DENY before ALLOW | Remove DENY or raise rule number |
| **Lab 03** | SG port 8080 not 80 | Change port to 80 |
| **Lab 04** | No subnet-RT association | `aws_route_table_association` |
| **Lab 05** | DNS hostnames disabled | `enable_dns_hostnames = true` |
| **Lab 06** | No NAT Gateway | Add `aws_nat_gateway` + private route |
| **Lab 07** | NAT GW in private subnet | Move to public subnet |
| **Lab 08** | Both peering routes missing | Add routes in BOTH route tables |
