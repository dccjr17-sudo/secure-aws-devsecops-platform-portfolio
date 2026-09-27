output "role_arn" {
  description = "ARN configured as the AWS_ROLE_TO_ASSUME GitHub Actions variable."
  value       = aws_iam_role.github_actions_ecr_publish.arn
}

output "role_name" {
  description = "Name of the least-privilege GitHub Actions publishing role."
  value       = aws_iam_role.github_actions_ecr_publish.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider in this AWS account."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
