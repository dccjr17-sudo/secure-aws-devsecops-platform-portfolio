# Development environment

This is the first environment composition. It uses the remote backend created by `../../bootstrap` and calls the reusable network module.

1. Apply `../../bootstrap` first.
2. Copy the two `*.example` files in this directory to `backend.hcl` and `terraform.tfvars`.
3. Insert the bootstrap outputs into `backend.hcl`; make the region/project values consistent across both files.
4. Run `terraform init -backend-config=backend.hcl`, then format, validate, plan, and review the change.

The development network intentionally has no NAT gateway or private-subnet default route in Phase 1. This keeps the foundation low-cost and prevents accidental egress. A workload deployment will select the required outbound connectivity approach deliberately rather than adding egress by default.

Phase 6 composes the `security_observability` module here. Its default plan creates an empty Secrets Manager container, KMS key, and multi-region CloudTrail audit trail. GuardDuty and Security Hub are intentionally disabled until `enable_threat_detection_services = true` is set in the ignored local `terraform.tfvars` after reviewing cost and trial implications. See [the Phase 6 runbook](../../../docs/runbooks/secrets-audit-detection.md) before applying.
