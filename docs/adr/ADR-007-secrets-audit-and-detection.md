# ADR-007: Managed configuration, audit trail, and cost-aware detection

- **Status:** Accepted
- **Date:** 2026-09-08

## Context

Phase 5 established controls before delivery, but the application still had no managed runtime configuration path and the lab had no account-level audit or threat-detection baseline. Putting a secret value in Terraform, a variable file, a container image, or a workflow would expose it through source control, image layers, CI logs, or Terraform state.

The project is a personal lab with an explicit low-cost constraint. GuardDuty and Security Hub are useful learning controls, but their trials can become billable. A Phase 6 design must therefore make ongoing-cost services deliberate rather than an invisible side effect of `terraform apply`.

## Decision

1. Create the Secrets Manager **container** with Terraform, but create no secret version. A value is added outside Terraform and is never committed, printed, or stored in state.
2. Use one customer-managed KMS key with automatic rotation for the new managed secret and a dedicated CloudTrail S3 destination. This is a targeted response to the Phase 5 KMS review; existing low-cost lab resources keep their separately documented AWS-managed encryption choices.
3. Create a private, versioned, KMS-encrypted S3 bucket and a multi-region CloudTrail management-event trail with file-integrity validation. Retain log objects for 90 days by default, then expire them to bound storage growth. Do not collect CloudTrail data events or duplicate delivery to CloudWatch Logs before there is a workload investigation requirement.
4. Define an IAM policy that can read exactly one managed secret and decrypt exactly through Secrets Manager for that secret. Leave the policy unattached until Phase 7 establishes the application's real workload identity; inventing an EC2 or ECS trust relationship now would broaden access without a workload to use it.
5. Make GuardDuty and Security Hub an explicit Terraform variable opt-in, defaulting to `false`. When enabled for validation, Security Hub starts without default standards because those controls require AWS Config and a separate cost and ownership decision.
6. Do not create an email, chat, or pager subscription in a personal lab without a named responder and escalation expectation. Phase 6 records and manually reviews a controlled GuardDuty finding; a future deployment phase must add owned alert routing before a public workload exists.

## Consequences

- The application supports `APP_CONFIG_SECRET_ID` and only asks AWS for configuration when that variable is supplied. Local tests and container builds continue to work without AWS credentials.
- A managed configuration value is protected from Terraform state, but operators must still avoid placing actual secret text in shell history, CI logs, pull requests, or evidence.
- CloudTrail gives the lab a durable, integrity-validated management-event history with a bounded retention period. It is not a substitute for workload logs or a full SIEM.
- A controlled GuardDuty sample finding can prove the detection path after the user consciously enables the two detection services. Until then, the default plan creates the KMS key, empty secret, and CloudTrail baseline only.
- The policy output is a least-privilege contract for the Phase 7 runtime identity, not evidence that an application already has cloud access.
