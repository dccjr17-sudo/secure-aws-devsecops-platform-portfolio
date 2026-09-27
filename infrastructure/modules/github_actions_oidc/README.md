# GitHub Actions OIDC module

Creates the AWS identity boundary for Phase 4. It has two distinct parts:

1. A GitHub Actions OpenID Connect (OIDC) provider for AWS Security Token Service (STS).
2. One role that can be assumed only by this repository's immutable GitHub identity on the `main` branch.

The role grants the minimum permissions Docker needs to publish an image to the project's private ECR repository. It cannot read or change the VPC, Terraform state bucket, other ECR repositories, or IAM resources.

The OIDC provider is an account-wide resource. Verify it does not already exist before applying this module. If an existing provider must be reused, import it into Terraform rather than create a duplicate.

No AWS access key, secret key, or session token is stored in GitHub. GitHub Actions receives a short-lived AWS session only after AWS verifies the workflow's audience and exact GitHub OIDC subject.
