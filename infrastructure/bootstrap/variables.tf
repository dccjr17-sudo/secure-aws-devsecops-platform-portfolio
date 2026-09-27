variable "aws_region" {
  description = "AWS region for Terraform state resources."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile used for bootstrap. Leave null to use the SDK default credential chain."
  type        = string
  default     = null
  nullable    = true
}

variable "project_name" {
  description = "Lowercase project slug used in resource names. Use a globally unique value for your lab."
  type        = string
  default     = "secure-aws-devsecops-platform"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,28}$", var.project_name))
    error_message = "project_name must be 3-28 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Environment label for state resources."
  type        = string
  default     = "shared"
}

variable "noncurrent_version_retention_days" {
  description = "Days to retain old state object versions."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days >= 30
    error_message = "Retain prior state versions for at least 30 days."
  }
}
