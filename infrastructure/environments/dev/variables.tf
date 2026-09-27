variable "aws_region" {
  description = "AWS region for the development environment. Match the bootstrap region."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "Named AWS CLI profile or Identity Center profile. Leave null to use the SDK default credential chain."
  type        = string
  default     = null
  nullable    = true
}

variable "project_name" {
  description = "Lowercase project slug used in resource names."
  type        = string
  default     = "secure-aws-devsecops-platform"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,28}$", var.project_name))
    error_message = "project_name must be 3-28 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,16}$", var.environment))
    error_message = "environment must be 2-16 lowercase letters, numbers, or hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the development VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "One public-subnet CIDR per selected Availability Zone."
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One private application-subnet CIDR per selected Availability Zone."
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention period for VPC Flow Logs."
  type        = number
  default     = 30

  validation {
    condition     = var.flow_log_retention_days >= 7 && var.flow_log_retention_days <= 3653
    error_message = "flow_log_retention_days must be between 7 and 3653."
  }
}

variable "audit_log_retention_days" {
  description = "Number of days to retain CloudTrail audit objects in the Phase 6 dedicated S3 bucket."
  type        = number
  default     = 90

  validation {
    condition     = var.audit_log_retention_days >= 90 && var.audit_log_retention_days <= 3653
    error_message = "audit_log_retention_days must be between 90 and 3653."
  }
}

variable "secret_recovery_window_in_days" {
  description = "Recovery period before the managed application configuration secret is permanently deleted."
  type        = number
  default     = 7

  validation {
    condition     = var.secret_recovery_window_in_days >= 7 && var.secret_recovery_window_in_days <= 30
    error_message = "secret_recovery_window_in_days must be between 7 and 30."
  }
}

variable "kms_key_deletion_window_in_days" {
  description = "Recovery period before the Phase 6 customer-managed KMS key is permanently deleted."
  type        = number
  default     = 7

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "kms_key_deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_threat_detection_services" {
  description = "Explicit opt-in for GuardDuty and Security Hub after reviewing their free-trial and ongoing charges."
  type        = bool
  default     = false
}

variable "enable_eks_foundation" {
  description = "Explicit opt-in for the Phase 7 EKS control plane, managed node group, NAT gateway, and related paid resources."
  type        = bool
  default     = false
}

variable "eks_kubernetes_version" {
  description = "EKS Kubernetes minor version. Confirm it remains under standard support before a live apply."
  type        = string
  default     = "1.35"

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.eks_kubernetes_version))
    error_message = "eks_kubernetes_version must be a Kubernetes minor version such as 1.35."
  }
}

variable "eks_cluster_public_access_cidrs" {
  description = "Trusted public IPv4 CIDRs allowed to reach the EKS API endpoint. Set only when enabling EKS; do not use 0.0.0.0/0."
  type        = list(string)
  default     = []
}

variable "eks_control_plane_log_retention_days" {
  description = "CloudWatch retention period for EKS control-plane logs."
  type        = number
  default     = 30

  validation {
    condition     = var.eks_control_plane_log_retention_days >= 7 && var.eks_control_plane_log_retention_days <= 3653
    error_message = "eks_control_plane_log_retention_days must be between 7 and 3653."
  }
}
