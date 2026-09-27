# Evidence guide

This directory contains the proof that the project works—not a dump of AWS screenshots. Favor concise, reproducible evidence.

## Good evidence to commit

- A manually redrawn architecture diagram with generic names.
- Sanitized output showing `terraform validate` succeeded.
- A short table of expected versus observed results.
- Redacted scanner summaries, test output, and deployment evidence.
- A brief note explaining a finding, mitigation, and verification.

## Never commit or upload

- AWS access keys, session tokens, passwords, private keys, `.env` files, state files, plans, or `terraform.tfvars`.
- Full AWS account IDs, ARNs, repository URLs, internal hostnames, public IP addresses, CloudTrail event data, or unredacted console screenshots.
- Anything related to an employer, a customer, a government system, or non-lab environments.

## Screenshot checklist

Before sharing an image, inspect browser tabs, address bars, account menus, breadcrumbs, resource IDs, ARNs, account IDs, regions if sensitive, IP addresses, log contents, and notification details. Crop or replace these values before saving evidence.

## Suggested per-phase evidence

| Artifact | Purpose |
| --- | --- |
| `phase-1-validation.md` | Terraform formatting/validation results and an explanation of the planned network |
| `phase-2-container-validation.md` | Local build, health check, non-root verification |
| `phase-3-image-registry-validation.md` | Private ECR publication, immutable-tag, scan, and finding-triage evidence |
| `phase-4-pipeline-validation.md` | Pull-request checks and OIDC role assumption evidence |
| `phase-5-security-gates-validation.md` | Security-gate results, dependency remediation, and safe secret-scanner demonstration |
| `phase-6-detection-validation.md` | Managed-configuration boundary, audit logging, controlled finding, and cost-safe remediation |
| `phase-7-kubernetes-workload-validation.md` | EKS foundation, private workload rollout, and sanitized endpoint validation |
