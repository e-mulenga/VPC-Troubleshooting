# Learning Notes — VPC Endpoints

## Gateway vs Interface Endpoints

| Feature | Gateway Endpoint | Interface Endpoint |
|---|---|---|
| Services | S3, DynamoDB only | Most AWS services |
| Cost | Free | ~$0.01/hour per AZ |
| Mechanism | Route table entry | Private IP (ENI) |

## The Key Rule

> Associate the endpoint with the route table used by the subnet
> where your instances live — not just any route table.

## Complete VPC Lab Series

| Lab | Bug | Fix |
|---|---|---|
| Lab 01 | Missing IGW route | aws_route → IGW |
| Lab 02 | NACL DENY before ALLOW | Remove DENY rule |
| Lab 03 | SG port 8080 not 80 | Change to port 80 |
| Lab 04 | No subnet-RT association | aws_route_table_association |
| Lab 05 | DNS hostnames disabled | enable_dns_hostnames = true |
| Lab 06 | No NAT Gateway | Add aws_nat_gateway + route |
| Lab 07 | NAT GW in private subnet | Move to public subnet |
| Lab 08 | Both peering routes missing | Add routes in both RTs |
| Lab 09 | Endpoint on wrong RT | Associate to private RT |
