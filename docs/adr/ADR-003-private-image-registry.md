# ADR-003: Use a private, immutable ECR repository with scan-on-push

**Status:** Accepted

**Date:** 2026-09-06

## Context

The local application image needs a private registry before it can be deployed to AWS. The registry must support image-vulnerability review and avoid tag replacement that could undermine traceability.

## Decision

- Use Amazon ECR as a private registry in the same region as the development platform.
- Enable a registry-level image scan-on-push rule scoped to this repository.
- Use immutable image tags; a published tag cannot be overwritten.
- Use ECR-managed AES-256 server-side encryption.
- Retain the ten most recent images through an ECR lifecycle policy.

## Consequences

The project must create a new, unique image tag for every push. This is intentional: later CI/CD will use a Git commit identifier rather than mutable tags such as `latest`. The initial manual image push uses the existing temporary-credential lab profile; Phase 4 replaces that with a least-privilege GitHub OIDC role. ECR Basic Scanning results are triaged against the actual installed package inventory before they are accepted as actionable findings.
