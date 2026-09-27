# Phase 3 validation: private image registry and scan triage

**Date:** 2026-09-07  
**Environment:** development, Oregon (`us-west-2`)  
**Sensitive values omitted:** AWS account ID, ECR repository URL, state-resource names, temporary credentials, and image digests.

## Expected and observed results

| Check | Expected | Observed |
| --- | --- | --- |
| Terraform validation | Valid configuration | `terraform validate` succeeded |
| Registry deployment | Private ECR repository with immutable tags, encryption, lifecycle retention, and scan-on-push | Applied successfully |
| Registry scan scope | Scan-on-push limited to this repository | Registry policy applied successfully |
| Image publication | A uniquely tagged image can be pushed | Tags `v0.1.0`, `v0.1.1`, and `v0.1.2` were accepted |
| Container tests | Both unit tests pass | 2 tests passed |
| Runtime health | Gunicorn serves `/health` | `status: ok` |
| Runtime identity | Application is not root | Application runs as `appuser` |

## Scan review and remediation

1. The first local image was published as an OCI image index. Amazon ECR Basic Scanning cannot scan that media type, so it was retained for traceability but not promoted.
2. A scan-compatible single-platform image based on `python:3.13-slim` was published as `v0.1.1`. It reported 6 critical, 11 high, 13 medium, and 1 low finding, primarily inherited from unused Debian Perl components and glibc.
3. The runtime was changed to `python:3.13-alpine`, then rebuilt, tested, health-checked, and published as `v0.1.2`.
4. The `v0.1.2` scan reported **0 critical**, **4 high**, and **1 medium** finding. The four high findings were attributed by ECR to `util-linux` version `2.42.1-r0`.
5. Container-package verification showed that `/bin/mount` and `/usr/bin/nsenter` resolve to BusyBox, while Alpine reported `util-linux` as not installed when removal was simulated. This is recorded as a scanner attribution mismatch, not dismissed without evidence.

## Residual-risk decision

The `v0.1.2` image is acceptable for this private development lab because it has no critical findings, the remaining high findings are tied to a package absent from the runtime inventory, and the service runs as an unprivileged user. The findings remain visible and are not waived for production. Phase 5 will add independent container scanning and an explicit policy gate so that critical findings block promotion and any exception has an owner, reason, and review date.

## Evidence retained outside Git

- Terraform plans and state remain local and ignored.
- AWS CLI output and Docker push logs were reviewed live but are not committed because they can contain account-specific identifiers.
