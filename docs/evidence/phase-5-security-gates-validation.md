# Phase 5 security-gates validation

## Baseline and remediation

| Check | Initial result | Remediation | Retest target |
| --- | --- | --- | --- |
| Python dependencies | `pip-audit` found `PYSEC-2026-2151` in Flask 3.1.2; fixed in Flask 3.1.3. | Updated `app/requirements.txt` to Flask 3.1.3. | Retest: no known vulnerabilities found. |
| Application SAST | Semgrep Community Edition scanned the two tracked application-source files with 1,074 Python and multi-language rules. | No source finding was reported in the baseline scan. | The SAST gate is green in the Phase 5 pull request. |
| Terraform policy checks | Checkov 3.3.16 passed 15 selected checks with zero failures. | Added the focused checks as a blocking gate and documented 11 broader findings separately. | The IaC gate is green in the Phase 5 pull request. |
| Container image | Prior ECR scan baseline: zero Critical findings; High findings remain under triage. | Trivy reports High and Critical findings and blocks on Critical. | The container gate is green with no Critical findings. |
| Secret scanner test | Gitleaks detected one synthetic generic API-key pattern and redacted it in output. | The test file was untracked and immediately removed. | Repository scan contains no synthetic test value. |

## Pull-request results

Phase 5 pull-request validation passed all seven checks:

1. Secret scan
2. Static application security scan
3. Python dependency vulnerability audit
4. Terraform security policy checks
5. Container vulnerability scan
6. Terraform formatting and validation
7. Application tests and image build

The first secret-scan attempt exposed a workflow-permission defect rather than a leak: the scanner could not read pull-request commit metadata. The workflow was corrected with read-only `pull-requests: read` permission, then the full validation passed. No write, AWS, or OIDC permission was added to the security-gate workflow.

## Publication-path result

A manually initiated `main` publication successfully ran all five reusable security gates before the separate build-and-publish job. The final job then used the existing short-lived GitHub OIDC role to publish an immutable ECR image. This validates that direct image publication cannot bypass the Phase 5 controls.

Only sanitized gate names, states, and remediation details are retained here; raw logs and values resembling credentials are not committed.
