variable "project_name" {
  description = "Project slug used in security resource names."
  type        = string
}

variable "environment" {
  description = "Environment name used in security resource names."
  type        = string
}

variable "audit_log_retention_days" {
  description = "Number of days to retain CloudTrail objects in the dedicated audit bucket."
  type        = number
  default     = 90

  validation {
    condition     = var.audit_log_retention_days >= 90 && var.audit_log_retention_days <= 3653
    error_message = "audit_log_retention_days must be between 90 and 3653."
  }
}

variable "secret_recovery_window_in_days" {
  description = "Recovery period before a deleted application configuration secret is permanently removed."
  type        = number
  default     = 7

  validation {
    condition     = var.secret_recovery_window_in_days >= 7 && var.secret_recovery_window_in_days <= 30
    error_message = "secret_recovery_window_in_days must be between 7 and 30."
  }
}

variable "kms_key_deletion_window_in_days" {
  description = "Recovery period before a deleted customer-managed KMS key is permanently removed."
  type        = number
  default     = 7

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "kms_key_deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_threat_detection_services" {
  description = "Explicit cost-aware opt-in for GuardDuty and Security Hub; leave false until ready to validate a sample finding."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to supported security resources."
  type        = map(string)
  default     = {}
}
