output "vpc_id" {
  description = "Development VPC ID."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs reserved for controlled ingress."
  value       = module.network.public_subnet_ids
}

output "private_application_subnet_ids" {
  description = "Private subnet IDs reserved for application workloads."
  value       = module.network.private_subnet_ids
}

output "vpc_flow_log_group_name" {
  description = "CloudWatch log group receiving VPC Flow Logs."
  value       = module.network.flow_log_group_name
}

output "ecr_repository_name" {
  description = "Private ECR repository name."
  value       = module.container_registry.repository_name
}

output "ecr_repository_url" {
  description = "Private ECR repository URL for image push operations."
  value       = module.container_registry.repository_url
}

output "github_actions_ecr_publish_role_arn" {
  description = "Configure this value as the AWS_ROLE_TO_ASSUME GitHub Actions repository variable."
  value       = module.github_actions_oidc.role_arn
}

output "application_configuration_secret_name" {
  description = "Set this name as APP_CONFIG_SECRET_ID only in the eventual runtime environment."
  value       = module.security_observability.application_configuration_secret_name
}

output "runtime_configuration_read_policy_arn" {
  description = "Attach this least-privilege policy to the workload identity created in a later deployment phase."
  value       = module.security_observability.runtime_configuration_read_policy_arn
}

output "audit_log_bucket_name" {
  description = "Private S3 bucket receiving the Phase 6 CloudTrail management-event trail."
  value       = module.security_observability.audit_log_bucket_name
}

output "audit_trail_name" {
  description = "Name of the multi-region CloudTrail management-event trail."
  value       = module.security_observability.audit_trail_name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID only when enable_threat_detection_services is true."
  value       = module.security_observability.guardduty_detector_id
}

output "eks_cluster_name" {
  description = "Phase 7 EKS cluster name when enable_eks_foundation is true."
  value       = try(module.eks_foundation[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint when enable_eks_foundation is true."
  value       = try(module.eks_foundation[0].cluster_endpoint, null)
}

output "application_pod_identity_role_arn" {
  description = "Pod Identity role bound only to the Phase 7 application service account."
  value       = try(module.eks_foundation[0].application_pod_identity_role_arn, null)
}
