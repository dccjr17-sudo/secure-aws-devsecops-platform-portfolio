# Security gates runbook

## What runs and when

Every pull request to `main` runs the existing Terraform and application checks plus the reusable Phase 5 security gates. The manual ECR publication workflow runs the same security gates before it can request AWS OIDC credentials or publish an image.

| Gate | It blocks | First response |
| --- | --- | --- |
| Gitleaks | A committed credential, token, or secret-like value | Revoke or rotate the real secret immediately. Remove it from the branch and assess whether history must be rewritten. Do not add a broad allow-list merely to make a check green. |
| Semgrep | A static-analysis finding in `app/src` | Fix the unsafe pattern. If a result is truly unreachable, document the reasoning and use the narrowest source-level suppression after review. |
| pip-audit | A known vulnerable Python dependency | Upgrade to a fixed version, run the unit tests, and keep the advisory ID and verification in Phase 5 evidence. |
| Checkov | A selected Terraform policy regression | Correct the Terraform design. Do not add a scanner-wide skip; evaluate a new policy only through an ADR and the tracked baseline. |
| Trivy | A Critical container vulnerability | Rebuild from a fixed base image or dependency. High findings are reported for triage and must not be silently ignored. |

## Safe local verification

Run these from the repository root after Docker Desktop is running. They mount the source read-only and do not contact AWS.

```powershell
docker run --rm --volume "${PWD}:/repo:ro" --workdir /repo bridgecrew/checkov:3.3.16 --directory infrastructure --framework terraform --check CKV_AWS_41,CKV_AWS_51,CKV_AWS_60,CKV_AWS_61,CKV_AWS_130,CKV_AWS_163,CKV_AWS_274,CKV_AWS_393,CKV2_AWS_11 --compact --quiet

docker run --rm --volume "${PWD}:/repo:ro" --workdir /repo --entrypoint semgrep semgrep/semgrep:latest scan --config auto --error app/src

docker run --rm --volume "${PWD}:/repo:ro" --workdir /repo python:3.13-slim sh -c "python -m pip install --disable-pip-version-check pip-audit==2.10.1 && python -m pip_audit --requirement app/requirements.txt --strict"
```

## Safe secret-scanner demonstration

Do not commit a real or synthetic secret. To prove Gitleaks detects a safe test pattern, create it only in the operating system temporary directory, scan it with the tool, then remove it immediately. Build the string at runtime so the repository itself never contains a secret-shaped value.

```powershell
$testDirectory = Join-Path $env:TEMP "phase5-gitleaks-test"
New-Item -ItemType Directory -Force $testDirectory | Out-Null
$testParts = @(
  "bXktc3ludGhldGljLXRlc3QtdmFsdWU",
  "tbmV2ZXItY3JlZGVudGlhbA"
)
$syntheticValue = $testParts -join ""
$assignmentName = "api" + "_key"
Set-Content -NoNewline -Path (Join-Path $testDirectory "test.txt") -Value "$assignmentName = `"$syntheticValue`""
docker run --rm --volume "${testDirectory}:/scan:ro" zricethezav/gitleaks:latest dir --redact --verbose /scan
Remove-Item -LiteralPath $testDirectory -Recurse -Force
```

The expected result is a detected synthetic generic API-key finding and a nonzero scan exit code. The final cleanup command removes the temporary directory; it is never staged or committed.

## Evidence to retain

Record only sanitized summaries: gate names, pass/fail state, advisory or control IDs, the remediation, and a retest result. Never commit scanner reports that could include credentials, account identifiers, registry addresses, or unredacted source excerpts.
