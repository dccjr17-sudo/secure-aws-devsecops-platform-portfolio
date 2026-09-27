# Project plan

## Project objective

Build and document a secure AWS application platform that demonstrates infrastructure automation, container security, CI/CD security, identity controls, monitoring, and Kubernetes operations. Each phase must leave behind a working artifact, a short decision record, validation evidence, and an interview-ready explanation.

## Delivery principles

- Build one platform incrementally instead of collecting unrelated labs.
- Prefer identity federation and short-lived credentials over static credentials.
- Apply least privilege, encryption, logging, and secure defaults from the first deployable resource.
- Keep costs explicit and avoid running paid services when not actively learning.
- Treat the Git history, documentation, and test evidence as portfolio artifacts.
- Do not use production data, employer data, real customer data, or unredacted console screenshots.

## Phases and exit criteria

### Phase 1 — Terraform foundation

**Build:** Terraform layout, protected remote state, development environment configuration, a two-AZ VPC, public/private subnet segmentation, and VPC Flow Logs.

**Exit criteria:** `terraform fmt`, `validate`, and an AWS-authenticated `plan` succeed. Remote state is versioned, encrypted, non-public, and locked. A sanitized diagram and rationale for the design are committed.

### Phase 2 — Containerized application

**Build:** A small health-check application, Dockerfile, non-root runtime user, local tests, and a documented local build/run command.

**Exit criteria:** The application builds and passes health checks locally; its image contains no secrets and runs as a non-root user.

### Phase 3 — Image registry and deployment target

**Build:** Private ECR repository, immutable tags, a repository-scoped image scanning configuration, and documented image publication and validation. The least-privilege GitHub OIDC role is introduced in Phase 4.

**Exit criteria:** A private repository receives an immutable application image; image scanning results are reviewed and documented, including any verified attribution mismatch or accepted residual risk.

### Phase 4 — CI/CD through GitHub Actions

**Build:** Pull-request validation and controlled image-publication workflows using GitHub-to-AWS OIDC federation.

**Exit criteria:** No long-lived AWS secret exists in GitHub. A pull request runs formatting, configuration validation, tests, and an image build; image publication requires an intentional main-branch gate.

**Status:** Complete — pull-request validation passed, a manually initiated main-branch workflow published an immutable ECR image through GitHub OIDC, and the resulting scan was reviewed.

### Phase 5 — Security scanning and policy gates

**Build:** Secret scanning, SAST, dependency scanning, IaC scanning, container scanning, and findings triage documentation.

**Exit criteria:** Critical findings block the pipeline or have a documented, time-bounded exception. One intentionally introduced safe test finding is detected and remediated.

**Status:** Complete — pull-request validation passed all seven checks, including the five security gates. The dependency baseline found Flask 3.1.2 vulnerable to `PYSEC-2026-2151`; it was upgraded to 3.1.3 and retested with no known vulnerabilities. A manually initiated `main` publication ran the same security gates before successfully publishing an immutable ECR image through the Phase 4 OIDC role. The safe synthetic secret test was detected and removed without being committed.

### Phase 6 — Secrets, audit, and detection

**Build:** Secrets Manager with least-privilege runtime access, KMS-backed encryption where appropriate, CloudTrail, GuardDuty, Security Hub, and log retention/alerting choices.

**Exit criteria:** Application configuration comes from a managed secret rather than source control; a controlled security event is generated, found, and explained.

**Status:** Complete — the KMS-encrypted configuration-secret container, narrow future-runtime policy, and dedicated CloudTrail trail and bucket were applied without changing existing resources. A controlled GuardDuty `Exfiltration:S3/MaliciousIPCaller` sample finding with severity 8.0 was generated, interpreted as test data, and followed by removal of the two temporary detection services. The Phase 7 workload identity will attach the prepared policy and provide the live runtime environment for `APP_CONFIG_SECRET_ID`.

### Phase 7 — Kubernetes/EKS

**Build:** EKS cluster and workload deployment, namespace/RBAC strategy, admission and image controls, network segmentation, centralized logging, and rollback guidance.

**Exit criteria:** The application deploys through CI/CD to EKS; access paths, security controls, operational evidence, and teardown steps are documented.

**Status:** In progress — the first, cost-gated foundation slice adds private EKS workers, one deliberately temporary egress path, EKS control-plane logs, access-entry authentication, and a Pod Identity role that can receive only the Phase 6 runtime secret-read policy. The workload slice adds a restricted namespace, dedicated service account, immutable-image deployment helper, internal-only service, health probes, and a network policy. No EKS resources are created unless the ignored local Terraform variables explicitly opt in.

## Definition of done for every phase

1. Infrastructure or code works from a documented command sequence.
2. The README and relevant runbook explain how to validate it.
3. At least one security decision and its trade-off is captured in `docs/adr/`.
4. Evidence is sanitized and stored according to `docs/evidence/README.md`.
5. The phase is summarized in two to four resume/interview talking points before moving on.
