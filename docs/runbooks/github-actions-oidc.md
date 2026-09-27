# GitHub Actions OIDC runbook

Use this runbook to create and validate the Phase 4 delivery path. The workflow uses identity federation; do not create AWS access keys or put credentials in GitHub.

## 1. Apply the OIDC and publishing role

From the development environment, authenticate with the lab profile and review the plan before applying it:

```powershell
cd infrastructure/environments/dev
terraform fmt main.tf outputs.tf ../../modules/github_actions_oidc
terraform validate
terraform plan
terraform apply
```

The focused formatting command intentionally avoids touching unrelated modules that may have local work in progress.

The plan should create exactly these Phase 4 IAM resources:

- the GitHub Actions OIDC provider;
- the narrow ECR publishing role; and
- the role's inline publishing policy.

Do not continue if the plan changes existing VPC, registry, state, or unrelated IAM resources.

## 2. Add the one GitHub Actions variable

After the apply succeeds, obtain the role ARN and the exact repository name locally:

```powershell
terraform output -raw github_actions_ecr_publish_role_arn
terraform output -raw ecr_repository_name
```

In GitHub, open **Settings → Secrets and variables → Actions → Variables**, then create this repository variable:

| Name | Value |
| --- | --- |
| `AWS_ROLE_TO_ASSUME` | the Terraform output from the command above |
| `ECR_REPOSITORY` | the `ecr_repository_name` Terraform output |

The role ARN is an identifier, not a credential. Do not put access keys, secrets, tokens, or passwords in GitHub Actions variables or secrets.

## 3. Validate each workflow

1. Push this Phase 4 branch and open a pull request. The **Pull request validation** workflow should pass Terraform formatting/configuration validation, application tests, and the image build without AWS access.
2. Merge the pull request only after the validation workflow passes.
3. On GitHub, open **Actions → Publish trusted ECR image → Run workflow** and select `main`.
4. Confirm the run completes. It builds a single-platform image and publishes an immutable `sha-<commit>` tag to the private ECR repository.
5. Use the existing ECR scan-on-push validation from Phase 3 to review the new image's scan result.

The workflow intentionally refuses to publish from a feature branch. Do not weaken the AWS trust policy or add static AWS credentials to bypass that control.

## Troubleshooting

- **AWS role assumption denied:** confirm the run was manually started from `main` and the `AWS_ROLE_TO_ASSUME` variable exactly matches the Terraform output. Review the exact GitHub OIDC subject condition; do not replace it with a wildcard.
- **ECR push denied:** confirm `ECR_REPOSITORY` exactly matches the current `ecr_repository_name` Terraform output and that Terraform applied the narrow ECR publishing policy. Do not attach broad policies such as `AdministratorAccess`.
- **Pull-request check fails during Terraform init:** it should run `terraform init -backend=false`; it must not receive remote-state or AWS credentials.
