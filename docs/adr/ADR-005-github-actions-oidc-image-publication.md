# ADR-005: Federate GitHub Actions to a narrow ECR publishing role

**Status:** Accepted

**Date:** 2026-09-07

## Context

The Phase 3 image was published from a local, short-lived lab session. The CI/CD workflow needs AWS access without placing a long-lived access key, secret key, or registry password in GitHub.

GitHub Actions can obtain an OpenID Connect (OIDC) token that AWS Security Token Service (STS) exchanges for a short-lived role session. That federation must be narrow enough that another repository, another branch, or a pull-request workflow cannot publish this project's image.

## Decision

- Create the GitHub Actions OIDC provider in AWS with the `sts.amazonaws.com` audience.
- Create one IAM role that trusts only the repository's immutable GitHub OIDC subject for `main`.
- Limit that role to the ECR authorization token action and the five API actions Docker needs to upload an image to this project's one ECR repository.
- Make the publishing workflow manual (`workflow_dispatch`) and require it to run from `main`.
- Keep PR validation separate and grant it only read access to repository contents; it cannot request an AWS OIDC token.
- Store the role ARN as a GitHub Actions variable because it identifies a role but is not an AWS credential. Store no static AWS credentials in GitHub.

## Consequences

The role session lasts at most one hour and AWS evaluates the GitHub token on every request to assume it. A workflow started from a feature branch cannot assume the role even if it is configured to request an OIDC token.

The role ARN must be copied from the Terraform output into the repository's `AWS_ROLE_TO_ASSUME` Actions variable after the local Terraform apply. This value is account-specific and is intentionally not written into Git-tracked files or evidence. If GitHub's OIDC subject configuration is changed, the trust condition must be reviewed rather than broadened with a wildcard.
