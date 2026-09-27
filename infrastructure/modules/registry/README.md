# Private container registry module

Creates the Phase 3 ECR repository for the application image.

- Private repository only; it is not internet-facing.
- Immutable image tags prevent a tag from being silently overwritten.
- A registry-level scan-on-push rule is scoped to this repository, enabling Amazon ECR Basic Scanning without changing the scan frequency of unrelated repositories.
- AES-256 server-side encryption protects images at rest.
- Lifecycle policy retains a bounded number of recent images to control storage growth.

Phase 4 adds a separate, least-privilege GitHub OIDC role that can publish images to this repository only.
