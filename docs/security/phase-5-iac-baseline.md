# Phase 5 Terraform security baseline

## Enforced controls

Phase 5 runs Checkov 3.3.16 against the Terraform source and blocks the following controls. The focused baseline continues to pass 15 checks with zero failures after the Phase 6 configuration is added.

| Control area | Check IDs | Why it blocks delivery |
| --- | --- | --- |
| Provider credentials | `CKV_AWS_41` | Terraform must not contain AWS access keys. |
| Private immutable registry | `CKV_AWS_51`, `CKV_AWS_163` | ECR image tags must be immutable and scanned on push. |
| Least-privilege identity | `CKV_AWS_60`, `CKV_AWS_61`, `CKV_AWS_274` | IAM roles must not be broadly assumable or use AdministratorAccess. |
| Network baseline | `CKV_AWS_130`, `CKV2_AWS_11` | Subnets must not assign public IPs by default and VPC Flow Logs must remain enabled. |
| GitHub federation | `CKV_AWS_393` | OIDC trust must constrain GitHub claims safely. |

## Broader findings retained for review

A full local scan after adding Phase 6 passed 151 checks and reported 21 unskipped findings: 11 existing low-cost lab decisions and 10 deliberate Phase 6 choices. These are documented individually rather than excluded in configuration. Checkov does not assign the business severity that determines release policy, so this table records the actual design decision and review target.

| Finding group | Check IDs | Current lab decision and compensating control | Review by |
| --- | --- | --- | --- |
| Customer-managed KMS keys | `CKV_AWS_119`, `CKV_AWS_136`, `CKV_AWS_145`, `CKV_AWS_158` | Phase 6 defines one rotating customer-managed key for the new managed secret and CloudTrail destination. State, ECR, and Flow Logs retain their documented AWS-managed encryption choice to avoid unrelated migration risk and cost. | Revisit before production data or workload deployment, no later than 2026-12-31 |
| State-bucket resilience and audit features | `CKV_AWS_18`, `CKV_AWS_62`, `CKV_AWS_144`, `CKV_AWS_300` | State is private, versioned, encrypted, and locked. Cross-region replication, a separate log destination, event notifications, and multipart cleanup are deferred to avoid adding services before a recovery/audit design exists. | Start of Phase 6, no later than 2026-12-31 |
| Flow-log retention and policy scope | `CKV_AWS_338`, `CKV_AWS_356` | Thirty-day retention controls cost. The CloudWatch delivery policy grants only required actions, though the AWS integration needs a wildcard resource. Revisit retention and policy boundaries with centralized logging. | Start of Phase 6, no later than 2026-12-31 |
| Default VPC security group | `CKV2_AWS_12` | No workload or public endpoint is attached. Explicit workload security groups are required before deployment; tighten the default group as part of that deployment design. | Before any workload deployment, no later than 2026-12-31 |
| Phase 6 KMS key policy | `CKV_AWS_109`, `CKV_AWS_111`, `CKV_AWS_356` | A customer-managed KMS key must retain an account-root administration statement so IAM can delegate use safely. The CloudTrail service statement is separately restricted by source account and exact trail ARN; the future runtime policy itself names one secret, one key, and the Secrets Manager encryption context only. | Review with the Phase 7 workload identity, no later than 2026-12-31 |
| Dedicated audit bucket | `CKV_AWS_18`, `CKV2_AWS_62`, `CKV_AWS_144` | The CloudTrail bucket is private, versioned, KMS-encrypted, and transport-enforced. S3 access logging would require a second log bucket, event notifications need an owned destination, and cross-region replication duplicates retained audit data; none is created without an incident-routing/recovery design. | Before a public workload or production data, no later than 2026-12-31 |
| Managed configuration rotation | `CKV2_AWS_57` | Terraform creates an empty configuration container, not a credential value. Automatic rotation needs a rotation function and a service that can safely consume changed credentials; add it only when a real rotating secret and workload exist. | With first credential-bearing secret, no later than Phase 7 |
| Detection-service scope | `CKV2_AWS_3` | GuardDuty is a per-account, per-region explicit opt-in in this personal lab, not an organization-wide delegated administrator design. The detector is disabled by default until the controlled-finding exercise is approved. | Before adding accounts or regions, no later than Phase 7 |
| CloudTrail alert and query delivery | `CKV_AWS_252`, `CKV2_AWS_10` | No SNS subscription is created without a named responder, and no CloudWatch Logs copy is created before a workload investigation use case. The Phase 6 trail is integrity-validated in private S3; controlled findings are reviewed in GuardDuty/Security Hub. | Before public exposure or an on-call commitment, no later than Phase 7 |

These tracked items are not a waiver for Critical findings. Secret, dependency, SAST, selected-IaC, and Critical-container gates continue to block the pipeline.
