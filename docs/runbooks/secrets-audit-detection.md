# Secrets, audit, and detection runbook

This runbook deploys and validates the Phase 6 security baseline in the dedicated lab account. It does not place credentials or secret values in Git, Terraform state, screenshots, or workflow logs.

## Before applying

1. Use only the named lab profile and verify its identity locally. Do not paste the output into this repository or a pull-request comment.
2. Confirm the CloudTrail retention choice. The default is 90 days.
3. Decide whether to enable GuardDuty and Security Hub **in this apply**. They default to `false`; enabling them begins service trials and may create charges after the trial period. The core secret and CloudTrail baseline does not require this opt-in.

From `infrastructure/environments/dev`:

```powershell
aws login --profile devsecops-lab
aws sts get-caller-identity --profile devsecops-lab
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
```

Review the plan before applying. It should not change the unrelated network module. The default plan creates the security KMS key, empty managed secret, least-privilege policy, CloudTrail destination, and trail. It must not include GuardDuty or Security Hub unless `enable_threat_detection_services = true` is set in the ignored local `terraform.tfvars` file.

```powershell
terraform apply tfplan
```

## Add a safe demonstration configuration

Terraform deliberately creates no `SecretString`. For a learning-only demonstration, add a harmless JSON message outside Terraform:

```powershell
$secretName = terraform output -raw application_configuration_secret_name
$demoConfiguration = '{"application_message":"Managed configuration loaded."}'
aws secretsmanager put-secret-value --secret-id $secretName --secret-string $demoConfiguration --region us-west-2 --profile devsecops-lab
aws secretsmanager describe-secret --secret-id $secretName --region us-west-2 --profile devsecops-lab --query '{Name:Name,RotationEnabled:RotationEnabled}' --output table
```

This demonstration value is not a credential. Never type a real password, token, API key, or customer value into a shell command: shell history and terminal captures can retain it. Add real values through an approved secret-entry process and keep the `APP_CONFIG_SECRET_ID` environment variable only in the future workload configuration. The application reads the JSON object at startup and never returns or logs the full object.

## Verify audit logging

```powershell
$trailName = terraform output -raw audit_trail_name
aws cloudtrail get-trail-status --name $trailName --region us-west-2 --profile devsecops-lab --query '{IsLogging:IsLogging,LatestDeliveryTime:LatestDeliveryTime}' --output table
```

Wait a few minutes after the first management action if `LatestDeliveryTime` is initially empty. Do not download or commit raw CloudTrail events; they can contain account and resource metadata.

## Enable and prove detection deliberately

Only perform this section after deciding that the temporary service trial is acceptable.

1. In the ignored local `terraform.tfvars`, set `enable_threat_detection_services = true`.
2. Repeat `terraform plan -out=tfplan`, verify it shows only the expected GuardDuty and Security Hub additions, then run `terraform apply tfplan`.
3. Create a provider-supplied sample finding. It is a controlled test event, not an attack.

```powershell
$detectorId = terraform output -raw guardduty_detector_id
aws guardduty create-sample-findings --detector-id $detectorId --region us-west-2 --profile devsecops-lab
$findingId = aws guardduty list-findings --detector-id $detectorId --region us-west-2 --profile devsecops-lab --query 'FindingIds[0]' --output text
aws guardduty get-findings --detector-id $detectorId --finding-ids $findingId --region us-west-2 --profile devsecops-lab --query 'Findings[0].{Type:Type,Severity:Severity,Title:Title,UpdatedAt:UpdatedAt}' --output table
aws securityhub describe-hub --region us-west-2 --profile devsecops-lab --query 'SubscribedAt' --output text
```

Confirm the finding is clearly labelled as a sample, record its generic type/severity and the fact that it was intentionally generated, then remove any local command output containing identifiers. Do not commit finding IDs, account values, raw event data, or unredacted console screenshots.

## Cost review and pause

Review the AWS billing dashboard before and after the detection exercise. To pause threat-detection services after validation, change the local opt-in back to `false`, inspect the destruction plan carefully, and apply it only if disabling the services is intended. Do not destroy the KMS key, managed secret, audit bucket, or CloudTrail trail without first reviewing their recovery windows and retained evidence.

## Evidence checklist

- `terraform validate` succeeds.
- The plan shows only intended Phase 6 resources.
- The secret metadata exists; the secret value is never shown.
- CloudTrail is logging.
- The controlled GuardDuty finding is visible and explained.
- The AWS billing/trial decision is recorded privately, without account identifiers.
