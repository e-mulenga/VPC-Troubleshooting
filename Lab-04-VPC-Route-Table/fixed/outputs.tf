output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.lab.id
}

output "instance_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.lab.public_ip
}

output "web_page_url" {
  description = "URL to test — broken: will not load | fixed: will load"
  value       = "http://${aws_instance.lab.public_ip}/"
}

output "route_table_id" {
  description = "Custom route table ID — check if it is associated to the subnet"
  value       = aws_route_table.lab.id
}

output "subnet_id" {
  description = "Subnet ID — check which route table it is associated to"
  value       = aws_subnet.lab.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "diagnosis_command" {
  description = "CLI command to check subnet route table associations"
  value       = "aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=${aws_subnet.lab.id} --query 'RouteTables[].Associations'"
}
