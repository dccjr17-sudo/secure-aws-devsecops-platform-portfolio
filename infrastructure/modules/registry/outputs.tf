output "repository_arn" {
  description = "ARN of the private ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the private ECR repository."
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "Repository URL used to tag and push container images."
  value       = aws_ecr_repository.this.repository_url
}
