# Secure AWS DevSecOps Application Platform

A sanitized public portfolio snapshot of an incrementally built AWS platform that demonstrates secure infrastructure delivery, containerization, CI/CD, detection, and Kubernetes operations. The live AWS environment was deliberately torn down after validation to prevent ongoing charges. This repository contains source code, architecture decisions, and sanitized evidence only—never credentials, account-specific configuration, Terraform state, or plan files.

## Why this project exists

The goal is to turn cloud-security knowledge into demonstrable engineering capability. Rather than completing disconnected labs, this repository evolves one application platform through infrastructure as code, secure software delivery, and cloud detection.

## Project roadmap

| Phase | Outcome | Key technologies |
| --- | --- | --- |
| 1 — foundation | Version-controlled Terraform, remote state, and a secure network baseline | Terraform, AWS IAM, S3, DynamoDB, VPC, CloudWatch Logs |
| 2 — application | A small containerized application with a repeatable local build | Docker, Python or Node.js |
| 3 — image delivery | Private image registry and immutable, scanned image publication | Amazon ECR |
| 4 — CI/CD | Automated validation and controlled image publication | GitHub Actions, OIDC |
| 5 — DevSecOps controls | Security checks at code, dependency, container, and IaC layers | Gitleaks, Semgrep, Trivy, Checkov |
| 6 — secrets and detection | Runtime secrets, audit logs, threat detection, and alerting | Secrets Manager, KMS, CloudTrail, GuardDuty, Security Hub |
| 7 — Kubernetes | A hardened, observable EKS deployment path | EKS, Kubernetes, Helm, network policies |

Detailed scope and success criteria are in [docs/PROJECT-PLAN.md](docs/PROJECT-PLAN.md).

## Architecture direction

Phase 1 establishes a two-AZ VPC with public and private application subnets. No workloads are exposed yet. The platform now has a private ECR registry, GitHub Actions with AWS OIDC instead of long-lived AWS keys, layered delivery security gates, a managed configuration boundary, and an integrity-validated CloudTrail audit trail. The Phase 7 foundation keeps Kubernetes workers private, captures control-plane audit logs, and uses an opt-in cost gate before any EKS resources can be created.

See [Phase 1 architecture](docs/architecture/phase-1-foundation.md) and [ADR-001](docs/adr/ADR-001-terraform-state-and-layout.md).

## Repository layout

```text
.
├── app/                         # Application code (added in Phase 2)
├── docs/                        # Architecture, decisions, runbooks, and sanitized evidence
├── infrastructure/
│   ├── bootstrap/                # One-time Terraform remote-state resources
│   ├── environments/dev/         # Development environment composition and backend config
│   └── modules/                  # Reusable VPC, flow-log, and registry modules
├── scripts/                      # Safe, repeatable helper scripts
└── .github/workflows/            # CI/CD workflows (added in Phase 4)
```

## Phase 1: first implementation steps

### 1. Prerequisites

- Install Terraform (1.6 or later) and AWS CLI v2.
- Authenticate with AWS IAM Identity Center or an approved named AWS profile. Do **not** create or paste access keys into this repository.
- Confirm the AWS account and region intended for the lab. This project is configured for Oregon (`us-west-2`); use that same region for both bootstrap and development state.
- For any live lab deployment, create a separate private repository and use a unique project slug; do not add a README, `.gitignore`, or license from GitHub because this folder already contains them. This public portfolio snapshot is intentionally not connected to a live AWS environment.

### 2. Bootstrap encrypted remote state

The bootstrap configuration creates a versioned, private S3 bucket and a DynamoDB lock table. It uses local state only for this initial one-time apply; keep the generated local `terraform.tfstate` private and never commit it.

```powershell
cd infrastructure/bootstrap
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: confirm Oregon, your devsecops-lab profile, and a unique project slug.
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Record the two Terraform outputs (`state_bucket_name` and `lock_table_name`) in a password manager or other private notes—not in screenshots.

### 3. Configure the development backend

```powershell
cd ../environments/dev
Copy-Item backend.hcl.example backend.hcl
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit both files using the bootstrap outputs and the same region/project settings.
terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
```

Review the plan carefully before applying. Phase 1 creates only the network and VPC flow logs. It intentionally does not create an NAT gateway, EKS cluster, or public application endpoint, which keeps initial cost and exposure low.

### 4. Capture safe evidence and commit

Use the checklist in [docs/evidence/README.md](docs/evidence/README.md). Commit source code and sanitized diagrams only—never state, plan files, credentials, account IDs, repository URLs, or console screenshots with sensitive values.

## Safety and cost guardrails

- `.tfstate`, plans, account-specific `*.tfvars`, and `backend.hcl` are ignored by Git.
- Terraform uses a named AWS profile or Identity Center session; there are no access keys in configuration.
- Initial VPC private subnets have no default internet route. A later documented decision will select NAT gateways or VPC endpoints based on workload needs and cost.
- Before Phase 2, create an AWS Budget and billing alert. Before EKS, review the cost estimate and set a lab teardown reminder.
- Follow the [Terraform workflow runbook](docs/runbooks/terraform-workflow.md) before every apply or destroy.

## Status

**Portfolio status:** The source and validation work through Phase 7 are preserved here for review. The live EKS environment, image registry contents, audit logs, and other billable AWS resources were deliberately removed after validation. Pull requests still run the local security and validation gates. The manual image-publication workflow is retained as an architectural reference, but this public copy has no AWS publishing role or live registry.

## License

No license is granted. This public repository is provided for portfolio review; contact the author before reusing its contents.
