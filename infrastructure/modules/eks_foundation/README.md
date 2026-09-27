# EKS foundation module

This module creates the Phase 7 Kubernetes foundation only when the development environment sets `enable_eks_foundation = true` in its ignored local `terraform.tfvars` file.

## What it creates

- A private-subnet EKS control plane with its private endpoint enabled and its public endpoint limited to explicit trusted CIDRs.
- A single private managed node (`t3.small`) that uses Amazon Linux 2023 and can pull images and reach AWS APIs through one NAT gateway.
- Control-plane API, audit, authenticator, controller-manager, and scheduler logs in a retained CloudWatch log group.
- EKS access-entry authentication (`API` mode), rather than the deprecated `aws-auth` ConfigMap approach.
- Core EKS add-ons managed in Terraform: VPC CNI, CoreDNS, kube-proxy, and the EKS Pod Identity Agent.
- A Pod Identity role for only `application/secure-platform`, attached to the Phase 6 policy that can retrieve the managed application configuration secret.

## Cost and availability trade-off

The one-node, one-NAT design is deliberately a learning environment, not a production topology. It keeps costs smaller while the cluster exists, but it is not AZ-resilient: the NAT gateway is in one public subnet and both private-subnet route tables use it. A production service should use resilient egress (or appropriate VPC endpoints) and a multi-node capacity plan.

EKS, the managed node, NAT gateway, public IPv4 address, storage, and data transfer are billable while provisioned. Keep the opt-in off outside an active lab and follow the Phase 7 teardown runbook when finished.

## Security choices

- The public Kubernetes API is never open to `0.0.0.0/0`; the caller must provide one or more trusted CIDRs.
- EKS uses access entries in `API` authentication mode. The Terraform-creating identity receives the initial administrator access; future deployment identities will be namespace-scoped.
- The node role can run Kubernetes and pull from ECR but cannot read the application secret.
- The application Pod Identity role receives only the Phase 6 secret-read policy. No AWS access keys are stored in the image, manifest, or repository.
- Kubernetes 1.28+ has EKS-managed envelope encryption for Kubernetes API data by default. This module intentionally avoids a second customer KMS key and its monthly/key-request cost.
