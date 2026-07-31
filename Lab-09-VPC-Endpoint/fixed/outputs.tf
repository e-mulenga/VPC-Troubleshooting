output "vpc_id"                  { value = aws_vpc.lab.id }
output "private_instance_id"    { value = aws_instance.private.id }
output "vpc_endpoint_id"        { value = aws_vpc_endpoint.s3.id }
output "public_route_table_id"  { value = aws_route_table.public.id }
output "private_route_table_id" { value = aws_route_table.private.id }
output "ssm_connect_command" {
  value = "aws ssm start-session --target ${aws_instance.private.id} --region ${var.aws_region}"
}
output "diagnosis_public_rt" {
  value = "aws ec2 describe-route-tables --route-table-ids ${aws_route_table.public.id} --query 'RouteTables[].Routes'"
}
output "diagnosis_private_rt" {
  value = "aws ec2 describe-route-tables --route-table-ids ${aws_route_table.private.id} --query 'RouteTables[].Routes'"
}
output "test_s3_command" { value = "aws s3 ls --region ${var.aws_region}" }
