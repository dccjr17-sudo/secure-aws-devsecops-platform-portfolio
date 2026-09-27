# Phase 6 security validation evidence

## Scope

This record proves managed-configuration handling, audit logging, and a controlled detection event without retaining a secret value, account identifier, ARN, finding ID, or raw CloudTrail event.

## Expected validation

| Control | Expected result | Safe evidence to record |
| --- | --- | --- |
| Terraform | Formatting and validation succeed; the plan contains only the intended Phase 6 changes | Pass/fail and resource categories only |
| Managed configuration | An empty Secrets Manager container exists and a harmless JSON demonstration object can be added outside Terraform | Secret name redacted or generic; never record the value |
| Runtime boundary | Application unit test proves no AWS call is made without `APP_CONFIG_SECRET_ID`; the future runtime policy names one secret and KMS key only | Test result and policy scope summary |
| Audit | CloudTrail is logging management events to the dedicated encrypted bucket | `IsLogging = true`; no bucket name or events |
| Detection | A GuardDuty sample finding is generated intentionally and its generic type/severity can be reviewed | Generic sample type and severity; no finding/account IDs |
| Alerting choice | No unmanaged email or chat destination is created without an incident owner | Decision reference to ADR-007 |

## Observed results

| Check | Observed result | Date | Notes |
| --- | --- | --- | --- |
| Pull-request checks | All seven required checks passed. | 2026-09-08 | Functional, formatting, secret, SAST, dependency, IaC-policy, and container checks were green. |
| Terraform validation | The default baseline applied: 12 added, 0 changed, 0 destroyed. | 2026-09-08 | The secret container, KMS key, narrow future-runtime policy, CloudTrail bucket, and trail were created. No plan/state artifact was committed. |
| Managed secret metadata | A managed configuration container exists; Terraform never created a secret value. | 2026-09-08 | Any demonstration value is added outside Terraform and is not recorded here. |
| CloudTrail logging | `IsLogging = True`. | 2026-09-08 | `LatestDeliveryTime` was initially empty immediately after trail creation, which is expected before first delivery completes. |
| GuardDuty sample finding | `Exfiltration:S3/MaliciousIPCaller`, severity `8.0`. | 2026-09-08 | Created with GuardDuty's provider-supplied sample-finding command. It is controlled test data, not a real incident. |
| Security Hub enabled | Enabled temporarily with GuardDuty for the controlled test, then removed. | 2026-09-08 | No default standards were enabled. |
| Cost guardrail | Temporary detection plan applied 2 additions, then applied 2 destructions. | 2026-09-08 | GuardDuty and Security Hub default to off in Terraform and were not left enabled after validation. |

## Explanation for review

The test finding was deliberately created with GuardDuty's sample-finding API. Its presence proves that the detector can produce and expose a finding; it does not represent malicious activity. `Exfiltration:S3/MaliciousIPCaller` is a high-severity scenario, so a real finding of this type would require investigation of the affected identity, S3 data access, and source IP. This exercise was correctly closed as controlled test data and the temporary services were disabled after the observation.

## Interview talking points

- I kept secret values out of Git and Terraform state by managing only the Secrets Manager container in Terraform.
- I added a rotating customer-managed KMS key and a private, integrity-validated CloudTrail management-event trail with bounded log retention.
- I used a one-secret, Secrets Manager-only decrypt policy as the contract for the future workload identity rather than creating an unused broad runtime role.
- I deliberately enabled GuardDuty and Security Hub only long enough to generate and interpret a high-severity sample finding, then removed the temporary services through a reviewed Terraform destroy plan.
