variable "project_name" {
  description = "Lowercase project slug used in resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "kubernetes_version" {
  description = "Supported EKS Kubernetes minor version."
  type        = string
}

variable "vpc_id" {
  description = "VPC that hosts the EKS control plane network interfaces and worker nodes."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs. The first subnet hosts the deliberately single-AZ NAT gateway for this temporary lab."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "EKS requires at least two public subnets across Availability Zones."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs across at least two Availability Zones for the EKS control plane and managed nodes."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS requires at least two private subnets across Availability Zones."
  }
}

variable "private_route_table_ids" {
  description = "Route tables that receive the temporary-lab default route through the NAT gateway."
  type        = list(string)

  validation {
    condition     = length(var.private_route_table_ids) >= 2
    error_message = "Provide each private application route table so worker nodes have controlled egress."
  }
}

variable "cluster_public_access_cidrs" {
  description = "Trusted public IPv4 CIDRs allowed to reach the EKS API endpoint."
  type        = list(string)

  validation {
    condition     = length(var.cluster_public_access_cidrs) > 0 && !contains(var.cluster_public_access_cidrs, "0.0.0.0/0")
    error_message = "Provide at least one trusted public CIDR and never use 0.0.0.0/0 for the EKS API endpoint."
  }
}

variable "control_plane_log_retention_days" {
  description = "CloudWatch retention period for EKS control-plane logs."
  type        = number
}

variable "runtime_configuration_policy_arn" {
  description = "Phase 6 least-privilege policy that reads only the managed application configuration secret."
  type        = string
}

variable "tags" {
  description = "Tags applied to supported resources."
  type        = map(string)
  default     = {}
}
