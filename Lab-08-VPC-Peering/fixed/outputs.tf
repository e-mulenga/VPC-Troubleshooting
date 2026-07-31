output "vpc_a_id" {
  description = "VPC A ID"
  value       = aws_vpc.vpc_a.id
}

output "vpc_b_id" {
  description = "VPC B ID"
  value       = aws_vpc.vpc_b.id
}

output "peering_connection_id" {
  description = "VPC Peering Connection ID — check status and routes"
  value       = aws_vpc_peering_connection.lab.id
}

output "peering_status" {
  description = "VPC Peering Connection status"
  value       = aws_vpc_peering_connection.lab.accept_status
}

output "instance_a_id" {
  description = "Instance A ID — connect via SSM"
  value       = aws_instance.instance_a.id
}

output "instance_b_id" {
  description = "Instance B ID — connect via SSM"
  value       = aws_instance.instance_b.id
}

output "instance_a_private_ip" {
  description = "Instance A private IP — ping this from Instance B"
  value       = aws_instance.instance_a.private_ip
}

output "instance_b_private_ip" {
  description = "Instance B private IP — ping this from Instance A"
  value       = aws_instance.instance_b.private_ip
}

output "ssm_connect_a" {
  description = "Connect to Instance A via SSM"
  value       = "aws ssm start-session --target ${aws_instance.instance_a.id} --region ${var.aws_region}"
}

output "ssm_connect_b" {
  description = "Connect to Instance B via SSM"
  value       = "aws ssm start-session --target ${aws_instance.instance_b.id} --region ${var.aws_region}"
}

output "diagnosis_command" {
  description = "Check routes in both route tables"
  value       = "aws ec2 describe-route-tables --route-table-ids ${aws_route_table.vpc_a.id} ${aws_route_table.vpc_b.id} --query 'RouteTables[].{Id:RouteTableId,Routes:Routes}'"
}

output "test_connectivity" {
  description = "After SSM connect to Instance A, run this to test"
  value       = "ping -c 3 ${aws_instance.instance_b.private_ip}"
}
