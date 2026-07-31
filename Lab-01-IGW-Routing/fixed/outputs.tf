output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.lab.id
}

output "instance_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.lab.public_ip
}

output "web_page_url" {
  description = "URL to access the web page (broken: will not load | fixed: will load)"
  value       = "http://${aws_instance.lab.public_ip}/"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "route_table_id" {
  description = "Route table ID — inspect routes here to find the bug"
  value       = aws_route_table.lab.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID — attached to VPC but route may be missing"
  value       = aws_internet_gateway.lab.id
}

output "diagnosis_hint" {
  description = "Hint for diagnosing the broken lab"
  value       = "Check routes in route table: aws ec2 describe-route-tables --route-table-ids ${aws_route_table.lab.id}"
}
