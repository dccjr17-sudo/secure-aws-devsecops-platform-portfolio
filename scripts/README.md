# Scripts

Only safe, documented, repeatable helper scripts belong here. Scripts must not embed credentials, account identifiers, or destructive defaults.

## `deploy-eks.ps1`

Deploys one existing immutable ECR image tag to the Phase 7 private EKS cluster. It verifies the supplied tag exists, configures local `kubectl` access, applies the reviewed base manifests, waits for rollout, and prints only Kubernetes resource status.

The script does not create cloud infrastructure, obtain long-lived credentials, use a mutable image tag, or write a secret value. The optional `-UseRuntimeSecret` switch sets only the existing secret *name* on the deployment after an operator has added a harmless value outside Terraform. See [the EKS workload deployment runbook](../docs/runbooks/eks-workload-deployment.md).
