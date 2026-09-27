# Security observability module

Phase 6 adds a small, deliberate security telemetry baseline without placing a secret value in Terraform state or silently enabling recurring-cost services.

## Resources and boundaries

- One customer-managed KMS key with automatic rotation encrypts the new Secrets Manager secret and dedicated CloudTrail S3 destination.
- Terraform creates an **empty** Secrets Manager container. Its value is added separately with the AWS CLI or console, so the value never enters Terraform code, plans, or state.
- The generated runtime policy can read only that secret and decrypt only through Secrets Manager for that secret. It is intentionally unattached until Phase 7 creates a real workload identity.
- A private, versioned, KMS-encrypted S3 bucket receives a multi-region CloudTrail management-event trail with file-integrity validation and a 90-day default retention lifecycle.
- GuardDuty and Security Hub require an explicit variable opt-in. They default to disabled because their free trials can become billable.

The module does not collect CloudTrail data events, ship CloudTrail to CloudWatch Logs, create an SNS subscription, or enable Security Hub standards. Each would add cost or operational ownership before the lab has a workload and an incident responder. The rationale and controlled-finding procedure are in [the Phase 6 runbook](../../../docs/runbooks/secrets-audit-detection.md).
