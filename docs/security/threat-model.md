# Initial threat model

This is a living, lightweight threat model. It identifies what the first phases must protect and drives later security controls.

| Asset or boundary | Primary risk | Initial control | Later validation |
| --- | --- | --- | --- |
| Git repository | A secret, account detail, or unsafe configuration is committed | Private repository, `.gitignore`, review checklist, no real credentials in source, and Gitleaks | Secret scanning blocks a deliberate safe test pattern (Phase 5) |
| GitHub-to-AWS delivery boundary | Long-lived cloud credentials are leaked or overprivileged | No AWS keys in GitHub; publishing is deferred until OIDC is defined | OIDC role trust policy is limited to this immutable repository identity and `main` (Phase 4) |
| Terraform state | Resource metadata or secrets are exposed, corrupted, or overwritten | Versioned non-public S3 state, encryption, DynamoDB lock table | Restore and concurrent-change behavior is documented (Phase 1) |
| AWS identity | Human or automation access exceeds the lab task | Named profile/Identity Center for humans; role-based access for automation | IAM policy review and access-denied tests (Phases 3–4) |
| VPC and workloads | Unnecessary inbound exposure or unobserved traffic | Private application subnets begin without a default internet route; Flow Logs enabled | Security-group, ingress, and egress tests (Phase 3) |
| Container supply chain | Vulnerable or tampered code reaches runtime | Small non-root image, private registry, and layered PR/publish security gates | Semgrep, pip-audit, Checkov, and Trivy block configured risks before publication (Phase 5) |
| Application configuration | Secrets are embedded in code, image layers, workflow logs, or Terraform state | An empty KMS-encrypted Secrets Manager container; value added outside Terraform | The app path is unit tested; Phase 7 attaches the one-secret, Secrets Manager-only decrypt policy to the workload identity |
| Kubernetes API and workload identity | An exposed cluster API, an overprivileged node, or a pod can access credentials it does not need | Private EKS nodes; API limited to explicit trusted CIDRs; access entries; a dedicated `application/secure-platform` service account; and a Pod Identity role with only the Phase 6 secret-read policy | Deploy a restricted pod, validate its private health endpoint, and demonstrate that only the workload identity retrieves the harmless runtime configuration (Phase 7) |
| Kubernetes application network | An application pod receives arbitrary inbound traffic or unrestricted protocol egress | Internal-only `ClusterIP` service, default-deny ingress, DNS-only and explicit Pod Identity credential egress, and HTTPS-only AWS-service egress | Validate through `kubectl port-forward`; replace broad HTTPS egress with private AWS endpoints in a production topology (Phase 7) |
| Detection and response | Suspicious activity is missed or cannot be investigated | VPC Flow Logs plus a KMS-encrypted, integrity-validated multi-region CloudTrail management trail | A controlled GuardDuty `Exfiltration:S3/MaliciousIPCaller` sample finding (severity 8.0) was generated, located, explained, and followed by removal of temporary detection services (Phase 6) |

## Assumptions and out of scope

- This is a personal lab in a dedicated AWS account; it does not process production, employer, customer, or government data.
- The application is intentionally simple. The engineering focus is secure delivery and operation, not application features.
- A public endpoint, if one is eventually needed, will be added only with an explicit architecture decision, TLS, security-group restrictions, and monitoring.
