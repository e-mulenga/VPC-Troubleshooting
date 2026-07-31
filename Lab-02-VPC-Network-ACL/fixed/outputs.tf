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

output "nacl_id" {
  description = "Network ACL ID — inspect rules here to find the bug"
  value       = aws_network_acl.lab.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab.id
}

output "diagnosis_command" {
  description = "CLI command to inspect NACL rules"
  value       = "aws ec2 describe-network-acls --network-acl-ids ${aws_network_acl.lab.id} --query 'NetworkAcls[].Entries'"
}
