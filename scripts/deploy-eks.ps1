[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")]
    [string]$ImageTag,

    [string]$AwsProfile = "devsecops-lab",

    [string]$AwsRegion = "us-west-2",

    [switch]$UseRuntimeSecret
)

$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$environmentDirectory = Join-Path $repositoryRoot "infrastructure/environments/dev"
$manifestDirectory = Join-Path $repositoryRoot "kubernetes/base"

Push-Location $environmentDirectory
try {
    $clusterName = terraform output -raw eks_cluster_name
    $repositoryUrl = terraform output -raw ecr_repository_url
    $repositoryName = terraform output -raw ecr_repository_name
    $runtimeSecretName = terraform output -raw application_configuration_secret_name
}
finally {
    Pop-Location
}

# Fail before changing Kubernetes if the exact immutable ECR tag is absent.
aws ecr describe-images `
    --repository-name $repositoryName `
    --image-ids "imageTag=$ImageTag" `
    --region $AwsRegion `
    --profile $AwsProfile `
    --output json | Out-Null

aws eks update-kubeconfig `
    --name $clusterName `
    --region $AwsRegion `
    --profile $AwsProfile | Out-Null

# Render the immutable ECR reference before applying. Applying the base
# placeholder first would briefly create an invalid ReplicaSet.
$renderedManifest = kubectl kustomize $manifestDirectory
if ($LASTEXITCODE -ne 0) {
    throw "Unable to render Kubernetes manifests."
}

$renderedManifest = $renderedManifest -replace "image: REPLACE_AT_DEPLOYMENT", "image: $repositoryUrl`:$ImageTag"
$renderedManifest | kubectl apply --filename -
if ($LASTEXITCODE -ne 0) {
    throw "Unable to apply Kubernetes manifests."
}

if ($UseRuntimeSecret) {
    kubectl set env deployment/secure-platform "APP_CONFIG_SECRET_ID=$runtimeSecretName" --namespace application
}

kubectl rollout status deployment/secure-platform --namespace application --timeout=5m
kubectl get deployment,pod,service,networkpolicy --namespace application
