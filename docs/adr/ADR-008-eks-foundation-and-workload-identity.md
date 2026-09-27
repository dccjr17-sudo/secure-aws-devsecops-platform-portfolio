# ADR-008: Cost-gated EKS foundation and workload identity

- **Status:** Accepted
- **Date:** 2026-09-12

## Context

The platform needs a Kubernetes deployment target for the private ECR image and the runtime configuration boundary established in Phase 6. The Phase 1 VPC has two private application subnets but deliberately had no default egress route. Amazon EKS requires an always-on managed control plane; private workers need controlled outbound access to pull ECR images and call AWS APIs.

This is a personal learning environment with an explicit cost ceiling. A production EKS architecture would use highly available egress, multiple workers, and a private delivery runner. Those choices add ongoing cost and operational scope that are not justified for a short-lived lab.

## Decision

1. Keep EKS disabled by default. The environment creates no EKS, NAT, public IPv4, node, or add-on resource until the ignored local `terraform.tfvars` explicitly sets `enable_eks_foundation = true`.
2. Place the EKS control plane network interfaces and a single managed `t3.small` worker in the existing two private application subnets. Add one NAT gateway in the first public subnet and route both private route tables through it while the lab exists.
3. Enable the private EKS API endpoint and a public endpoint limited to a manually supplied trusted CIDR. The configuration rejects `0.0.0.0/0`.
4. Use `API` authentication and EKS access entries rather than the deprecated `aws-auth` ConfigMap. The Terraform-creating identity receives initial administrator access.
5. Enable EKS control-plane API, audit, authenticator, controller-manager, and scheduler logging with 30-day retention by default.
6. Use EKS Pod Identity for `application/secure-platform`. Attach the Phase 6 secret-read policy only to that role; the node role cannot read the application configuration secret.
7. Use EKS-managed envelope encryption for Kubernetes API data rather than create another customer KMS key. Kubernetes versions 1.28 and later receive this protection by default.

## Consequences

- A live EKS learning session is intentionally billable and must end with a reviewed `terraform destroy` once evidence is captured.
- One NAT gateway is a cost-saving single point of failure and can cause cross-AZ egress traffic. This is documented lab debt, not a production recommendation.
- A GitHub-hosted runner cannot be safely allowlisted with a fixed personal CIDR. The next Phase 7 slice must choose a delivery path that preserves restricted API access, such as a self-hosted runner in the VPC or a deliberately time-bounded, reviewed access exception.
- Pod Identity keeps runtime credentials out of the container image and source code, but the namespace and service-account names are an intentional security boundary and must not be changed casually.
