output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "private_instance_id" {
  description = "Private EC2 instance ID — use with SSM Session Manager"
  value       = aws_instance.private.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID — check which subnet it is in"
  value       = aws_nat_gateway.lab.id
}

output "nat_gateway_subnet_id" {
  description = "Subnet where NAT Gateway is placed — this reveals the bug"
  value       = aws_nat_gateway.lab.subnet_id
}

output "public_subnet_id" {
  description = "Public subnet ID — NAT Gateway should be here"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID — NAT Gateway should NOT be here"
  value       = aws_subnet.private.id
}

output "ssm_connect_command" {
  description = "Connect to private instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.private.id} --region ${var.aws_region}"
}

output "diagnosis_command" {
  description = "Check which subnet the NAT Gateway is in"
  value       = "aws ec2 describe-nat-gateways --nat-gateway-ids ${aws_nat_gateway.lab.id} --query 'NatGateways[].{Id:NatGatewayId,Subnet:SubnetId,State:State}'"
}
