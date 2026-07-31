output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "private_instance_id" {
  description = "Private EC2 instance ID — use with SSM Session Manager"
  value       = aws_instance.private.id
}

output "private_route_table_id" {
  description = "Private route table ID — inspect routes to find the bug"
  value       = aws_route_table.private.id
}

output "ssm_connect_command" {
  description = "Command to connect to private instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.private.id} --region ${var.aws_region}"
}

output "diagnosis_command" {
  description = "Check what routes exist in the private route table"
  value       = "aws ec2 describe-route-tables --route-table-ids ${aws_route_table.private.id} --query 'RouteTables[].Routes'"
}

output "nat_gateway_status" {
  description = "NAT Gateway status — MISSING in broken state"
  value       = "❌ No NAT Gateway created — run diagnosis_command to confirm missing route"
}
