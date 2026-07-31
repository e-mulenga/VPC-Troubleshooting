output "instance_id"         { value = aws_instance.lab.id }
output "instance_public_ip"  { value = aws_instance.lab.public_ip }
output "web_page_url"        { value = "http://${aws_instance.lab.public_ip}/" }
output "nacl_id"              { value = aws_network_acl.lab.id }
output "vpc_id"                { value = aws_vpc.lab.id }
output "diagnosis_command" {
  value = "aws ec2 describe-network-acls --network-acl-ids ${aws_network_acl.lab.id} --query 'NetworkAcls[].Entries[?Egress==`true`]'"
}
