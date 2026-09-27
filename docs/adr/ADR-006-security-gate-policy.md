# ADR-006: Layered security gates before image publication

- **Status:** Accepted
- **Date:** 2026-09-08

## Context

Phase 4 proved that a GitHub Actions workflow can publish an immutable image to private ECR with a narrowly scoped, short-lived AWS OIDC session. Functional tests and a Docker build alone do not prevent committed secrets, vulnerable dependencies, unsafe application patterns, insecure Terraform changes, or critical container vulnerabilities from reaching that publish step.

The repository is private and is intentionally kept on a no-additional-cost learning path. The Phase 5 control must therefore run without static cloud credentials, an external SaaS token, or a GitHub Advanced Security entitlement.

## Decision

Add a reusable `security-gates.yml` workflow and require it in two places:

1. Pull-request validation invokes it before a change can be merged.
2. The manual ECR publication workflow invokes it before its AWS-enabled publish job can start.

The workflow has only `contents: read` permission. It cannot request an OIDC token or access AWS. The ECR publish job retains its separate `id-token: write` permission and runs only after all gates pass.

| Layer | Tool and policy | Blocking behavior |
| --- | --- | --- |
| Committed secrets | Gitleaks scans complete Git history | Any detected secret fails the workflow. |
| Application SAST | Semgrep Community Edition scans `app/src` with the current community ruleset | Any reported finding fails the workflow. |
| Python dependencies | `pip-audit` audits `app/requirements.txt` against public advisories | Any known vulnerability, or an incomplete dependency collection, fails the workflow. |
| Terraform | Checkov enforces a focused allow-list of access-key, IAM, ECR, network, and OIDC controls | Any selected control failure fails the workflow. |
| Container image | Trivy reports High and Critical findings, then enforces a separate Critical-only gate | Critical findings fail the workflow; High findings require documented triage. |

Scanner images and the Python audit package are pinned to the versions verified during Phase 5. The two Trivy passes make the current High findings visible without treating them as a silent success.

## Consequences

- A change must satisfy both functional and security validation before publishing an image.
- The security scans do not need AWS authentication, so a malicious pull request cannot obtain the ECR publish role through this workflow.
- The existing application image has High findings but no Critical findings. High findings remain visible in workflow logs and ECR scan evidence while the base image and package attribution are reviewed.
- A complete Checkov run has broader findings that reflect deliberate lab cost or architecture decisions. Those items are tracked in [the Phase 5 IaC baseline](../security/phase-5-iac-baseline.md); they are not hidden by blanket scanner suppression.
- Critical findings have no active exception. They block delivery until remediated. Any future exception must name the finding, owner, compensating control, expiry date, and revalidation evidence.
