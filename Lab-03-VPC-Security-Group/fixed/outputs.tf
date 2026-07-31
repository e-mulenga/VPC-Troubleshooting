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

output "security_group_id" {
  description = "Security Group ID — inspect inbound rules here to find the bug"
  value       = aws_security_group.lab.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "diagnosis_command" {
  description = "CLI command to inspect Security Group inbound rules"
  value       = "aws ec2 describe-security-groups --group-ids ${aws_security_group.lab.id} --query 'SecurityGroups[].IpPermissions'"
}
