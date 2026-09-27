# EKS workload deployment runbook

Use this runbook only after the Phase 7 EKS foundation is active and the `kubectl get nodes` validation shows a `Ready` node. The Kubernetes API is restricted to the trusted CIDR configured in the ignored local Terraform variables.

## Deploy an immutable ECR image

1. In PowerShell at the repository root, list only tagged images. Do not share image digests, account identifiers, or endpoints in public evidence.

```powershell
cd infrastructure/environments/dev
$repositoryName = terraform output -raw ecr_repository_name
aws ecr describe-images --repository-name $repositoryName --region us-west-2 --profile devsecops-lab --query "imageDetails[?imageTags != null].imageTags[]" --output table
cd ../../..
```

2. Select an existing immutable tag, preferably `sha-<commit>`, and deploy it. The script verifies the tag exists before it applies the namespace and workload manifests.

```powershell
.\scripts\deploy-eks.ps1 -ImageTag "sha-REPLACE_WITH_EXISTING_COMMIT"
```

The first deployment intentionally leaves `APP_CONFIG_SECRET_ID` blank. This proves the container, health probes, service account, `restricted` Pod Security profile, internal service, and network policy without attempting to read an empty Secrets Manager container.

The deployment script renders the selected immutable image into the manifests before it sends them to Kubernetes. The application image and manifest both use the explicit non-root UID and GID `10001`; this lets Kubernetes verify the restricted Pod Security setting without relying on an image-defined user name.

## Validate privately

```powershell
kubectl get deployment,pod,service,networkpolicy -n application
kubectl port-forward service/secure-platform 8080:80 -n application
```

In a second PowerShell window, while port-forward is running:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
Invoke-RestMethod http://127.0.0.1:8080/
```

Stop port-forward with `Ctrl+C` when finished. The service remains cluster-internal; no load balancer or public application endpoint is created.

## Validate Phase 6 configuration through Pod Identity

Only run this optional step with a harmless lab value. It changes the secret value outside Terraform by design; never paste secrets in the repository, pull request, issue, or screenshot.

```powershell
cd infrastructure/environments/dev
$secretName = terraform output -raw application_configuration_secret_name
aws secretsmanager put-secret-value --secret-id $secretName --secret-string '{"application_message":"Runtime configuration loaded through Pod Identity."}' --region us-west-2 --profile devsecops-lab
cd ../../..
.\scripts\deploy-eks.ps1 -ImageTag "sha-REPLACE_WITH_EXISTING_COMMIT" -UseRuntimeSecret
```

Then repeat the private port-forward test. The `/` endpoint should return only the harmless `application_message`, which demonstrates the workload could read the managed secret through the Pod Identity role. Do not capture the complete secret value as evidence.

## Roll back

To roll back the application, rerun the script with a previously validated immutable image tag. The deployment uses Kubernetes rolling-update defaults and keeps the service name stable.

## Remove the lab safely

Do not run `terraform destroy` or `terraform plan -destroy`; those commands target the whole environment. Instead, edit the ignored local `terraform.tfvars` and set:

```hcl
enable_eks_foundation = false
```

Then, from `infrastructure/environments/dev`, run a normal plan and verify it removes only Phase 7 resources before applying it:

```powershell
terraform plan -out=phase7-teardown.tfplan
terraform apply phase7-teardown.tfplan
```
