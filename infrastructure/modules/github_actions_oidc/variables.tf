variable "project_name" {
  description = "Project slug used in the IAM role name."
  type        = string
}

variable "environment" {
  description = "Environment name used in the IAM role name."
  type        = string
}

variable "github_oidc_subject" {
  description = "Exact immutable GitHub OIDC subject allowed to assume the role."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the one ECR repository this role may publish to."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
