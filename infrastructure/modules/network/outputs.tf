output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private application subnet IDs."
  value       = aws_subnet.private_application[*].id
}

output "private_application_route_table_ids" {
  description = "Route table IDs for the private application subnets."
  value       = aws_route_table.private_application[*].id
}

output "flow_log_group_name" {
  description = "CloudWatch log group name receiving VPC Flow Logs."
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}
