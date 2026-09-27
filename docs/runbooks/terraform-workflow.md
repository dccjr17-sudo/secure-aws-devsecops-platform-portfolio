# Terraform workflow runbook

## Before any change

1. Confirm you are authenticated to the intended **lab** AWS account and named profile.
2. Confirm the selected region and environment are correct.
3. Pull the current private repository changes.
4. Never work with static AWS access keys copied into shell history or files.

## Standard change workflow

```powershell
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
# Review every create, change, and destroy action before continuing.
terraform apply tfplan
```

Do not commit `tfplan`, `terraform.tfstate`, `.terraform/`, `backend.hcl`, or account-specific `terraform.tfvars`.

## After an apply

1. Verify only the resources shown in the plan exist.
2. Record a sanitized validation result in `docs/evidence/`.
3. Check AWS Cost Explorer/Budgets when a phase adds a billable service.
4. Commit the Terraform source, documentation, and sanitized evidence together.

## Destruction rule

Destroy application resources only after confirming their exact environment and impact. The bootstrap state bucket and lock table must be destroyed last because other Terraform configurations depend on them.
