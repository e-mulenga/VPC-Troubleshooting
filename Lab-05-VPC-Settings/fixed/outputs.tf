output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.lab.id
}

output "instance_public_ip" {
  description = "Public IP — this will have a value even in broken state"
  value       = aws_instance.lab.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name — EMPTY in broken state, populated in fixed state"
  value       = aws_instance.lab.public_dns
}

output "web_page_url_by_dns" {
  description = "URL using DNS name — broken: empty | fixed: full URL"
  value       = "http://${aws_instance.lab.public_dns}/"
}

output "web_page_url_by_ip" {
  description = "URL using IP — works in both broken and fixed (useful for testing)"
  value       = "http://${aws_instance.lab.public_ip}/"
}

output "vpc_id" {
  description = "VPC ID — check DNS settings on this VPC"
  value       = aws_vpc.lab.id
}

output "diagnosis_command" {
  description = "CLI command to check VPC DNS settings"
  value       = "aws ec2 describe-vpc-attribute --vpc-id ${aws_vpc.lab.id} --attribute enableDnsHostnames"
}
