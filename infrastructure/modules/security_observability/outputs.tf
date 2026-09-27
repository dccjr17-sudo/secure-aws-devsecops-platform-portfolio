output "application_configuration_secret_arn" {
  description = "ARN of the empty managed-secret container. Add its value outside Terraform."
  value       = aws_secretsmanager_secret.application_configuration.arn
}

output "application_configuration_secret_name" {
  description = "Name supplied to the application's APP_CONFIG_SECRET_ID environment variable."
  value       = aws_secretsmanager_secret.application_configuration.name
}

output "runtime_configuration_read_policy_arn" {
  description = "Least-privilege policy to attach to the future application runtime identity."
  value       = aws_iam_policy.runtime_configuration_read.arn
}

output "security_kms_key_arn" {
  description = "Customer-managed key used by the new secret and CloudTrail audit destination."
  value       = aws_kms_key.security.arn
}

output "audit_log_bucket_name" {
  description = "Dedicated private S3 bucket receiving CloudTrail management-event logs."
  value       = aws_s3_bucket.audit_logs.id
}

output "audit_trail_name" {
  description = "Multi-region CloudTrail name."
  value       = aws_cloudtrail.audit.name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID when the explicit threat-detection opt-in is enabled; otherwise null."
  value       = try(aws_guardduty_detector.this[0].id, null)
}

output "securityhub_enabled" {
  description = "Whether this configuration was explicitly opted in to enable Security Hub."
  value       = var.enable_threat_detection_services
}
