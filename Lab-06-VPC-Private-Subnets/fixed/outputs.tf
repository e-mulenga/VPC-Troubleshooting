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

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.lab.id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public Elastic IP"
  value       = aws_eip.nat.public_ip
}

output "private_route_table_id" {
  description = "Private route table ID"
  value       = aws_route_table.private.id
}

output "ssm_connect_command" {
  description = "Command to connect to private instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.private.id} --region ${var.aws_region}"
}

output "test_connectivity_commands" {
  description = "Commands to test outbound internet from private instance"
  value       = "After SSM connect: curl -I https://aws.amazon.com && ping -c 3 8.8.8.8"
}
