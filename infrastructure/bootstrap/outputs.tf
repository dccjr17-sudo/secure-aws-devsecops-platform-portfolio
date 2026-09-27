output "state_bucket_name" {
  description = "Private, versioned S3 bucket for Terraform environment state."
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "DynamoDB table used to lock Terraform state changes."
  value       = aws_dynamodb_table.terraform_lock.name
}

output "aws_region" {
  description = "Region selected for remote state resources."
  value       = var.aws_region
}
