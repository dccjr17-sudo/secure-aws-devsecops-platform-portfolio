# Phase 1 architecture — Terraform foundation

```text
Local machine (AWS Identity Center / named profile)
        |
        | Terraform bootstrap (one time)
        v
  S3 state bucket  <---->  DynamoDB state lock table
  - versioned              - on-demand capacity
  - encrypted              - server-side encryption
  - blocked public access
        |
        | Terraform dev environment (remote state)
        v
AWS VPC (two Availability Zones)
├── Public subnets
│   ├── Internet gateway route
│   └── Reserved for a future load balancer / controlled ingress
├── Private application subnets
│   ├── No default internet route in Phase 1
│   └── Reserved for future application workloads
└── VPC Flow Logs → CloudWatch Logs
```

## Security decisions

- **State is remote and protected.** Terraform state can contain sensitive metadata, so it is stored in a non-public, versioned, encrypted bucket. DynamoDB state locking prevents conflicting updates.
- **Two AZs are represented early.** This supports later high-availability design without rebuilding the network layout.
- **Private subnets start without outbound internet access.** NAT gateways are intentionally deferred; they add recurring cost and should be justified by a real workload. A later phase will compare NAT gateways with private VPC endpoints.
- **Network telemetry starts at the foundation.** VPC Flow Logs create visibility before the first application deployment.

## Deliberate limitations

Phase 1 does not deploy an app, public DNS name, security groups, NAT gateway, ECR repository, ECS service, EKS cluster, or GitHub identity provider. Those are phase-specific decisions and will be added only after the Terraform workflow is validated.
