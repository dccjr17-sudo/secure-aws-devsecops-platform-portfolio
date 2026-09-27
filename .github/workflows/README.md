# CI/CD workflows

Phase 4 adds two deliberately separate workflows, and Phase 5 adds a reusable security-gate workflow:

- `pull-request-validation.yml` runs Terraform formatting/configuration validation, Python unit tests, and a local image build for every pull request targeting `main`. It has no AWS permissions and cannot request an OIDC token.
- `security-gates.yml` runs Gitleaks, Semgrep, pip-audit, selected Checkov controls, and Trivy. It has only read access and cannot request an AWS OIDC token. Pull requests and image publication both call it.
- Pull-request validation also formats and validates the environment composition plus the OIDC and security-observability Terraform modules. It still has no AWS permissions.
- `publish-ecr-image.yml` is a manually dispatched workflow. It can run only from `main`, waits for the security gates, receives a short-lived AWS session through GitHub OIDC, and publishes an immutable commit-SHA image tag to this project's private ECR repository.

The publishing workflow reads two GitHub **Actions variables**:

- `AWS_ROLE_TO_ASSUME` is an IAM role ARN, not a credential; it identifies the short-lived role AWS should evaluate.
- `ECR_REPOSITORY` is the Terraform output naming the one private ECR repository that role can publish to.

Never store AWS access keys, secret keys, session tokens, or registry passwords in GitHub variables or secrets.

See [the OIDC runbook](../../docs/runbooks/github-actions-oidc.md) for the safe setup and validation sequence.
See [the security-gates runbook](../../docs/runbooks/security-gates.md) for remediation and local validation.
