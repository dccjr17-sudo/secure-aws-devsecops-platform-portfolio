# EKS foundation runbook

Use this runbook only after the Phase 7 foundation pull request has been reviewed and merged. A live EKS lab is billable while its control plane, node, NAT gateway, public IPv4 address, storage, and data transfer exist.

## Before enabling the lab

1. Authenticate with the named AWS Identity Center profile.
2. Confirm the project is on `main`, and pull the latest changes.
3. From `infrastructure/environments/dev`, get the current public IPv4 address. Do not commit or paste it into an issue, pull request, screenshot, or evidence file.

```powershell
$trustedCidr = "$(Invoke-RestMethod -Uri 'https://checkip.amazonaws.com').Trim()/32"
```

4. Edit the ignored local `terraform.tfvars` file and add only the following Phase 7 values. Replace the value with the variable already held in your PowerShell session; do not commit the result.

```hcl
enable_eks_foundation           = true
eks_kubernetes_version          = "1.35"
eks_cluster_public_access_cidrs = ["YOUR_TRUSTED_PUBLIC_IPV4/32"]
```

Never use `0.0.0.0/0`. It is rejected by the Terraform configuration.

## Plan and create

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
```

Review that the plan creates the EKS control plane, one managed node, a NAT gateway, an Elastic IP, four core add-ons, logging, and the narrowly scoped Pod Identity role. Stop if an existing Phase 1–6 resource is unexpectedly replaced or destroyed.

Only then:

```powershell
terraform apply tfplan
```

Creation can take several minutes. The next Phase 7 slice will add the workload manifest, deployment path, and sanitized validation evidence.

## Teardown

After the live validation and evidence collection are complete, do **not** use `terraform destroy` or `terraform plan -destroy`: those commands would target every Terraform-managed Phase 1–7 resource in this environment.

Instead, edit the ignored local `terraform.tfvars` file and turn off only the Phase 7 module:

```hcl
enable_eks_foundation = false
```

Then create a normal plan from the same directory:

```powershell
terraform plan -out=phase7-teardown.tfplan
```

Review the plan carefully. It should remove only the Phase 7 EKS resources and restore the private subnet route tables to their original no-default-egress state. It must not remove the Phase 1–6 baseline. Only then apply it:

```powershell
terraform apply phase7-teardown.tfplan
```
