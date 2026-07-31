# Troubleshooting — VPC Lab 09

## Step 1 — Check which route table the endpoint is on

```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)" \
  --query "VpcEndpoints[].{Id:VpcEndpointId,RouteTables:RouteTableIds}"
# BROKEN: shows public RT ID
# FIXED:  shows private RT ID
```

## Step 2 — Check route tables for S3 prefix list

```bash
# Public RT — S3 route will be HERE in broken state (wrong)
aws ec2 describe-route-tables \
  --route-table-ids $(terraform output -raw public_route_table_id) \
  --query "RouteTables[].Routes"

# Private RT — S3 route should be HERE (only in fixed state)
aws ec2 describe-route-tables \
  --route-table-ids $(terraform output -raw private_route_table_id) \
  --query "RouteTables[].Routes"
```

## Step 3 — Test from private instance

```bash
aws ssm start-session --target $(terraform output -raw private_instance_id)
aws s3 ls --region us-east-1
# BROKEN: connection timeout
# FIXED:  lists buckets successfully
```

## Fix — CLI

```bash
aws ec2 modify-vpc-endpoint \
  --vpc-endpoint-id $(terraform output -raw vpc_endpoint_id) \
  --remove-route-table-ids $(terraform output -raw public_route_table_id) \
  --add-route-table-ids $(terraform output -raw private_route_table_id)
```
