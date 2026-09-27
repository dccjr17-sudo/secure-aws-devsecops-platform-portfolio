# Network module

Creates the Phase 1 network baseline:

- VPC with DNS support
- Two or more public subnets with an internet-gateway route
- A matching set of private application subnets without a default internet route
- VPC Flow Logs delivered to CloudWatch Logs through a dedicated IAM role

The module deliberately does not create security groups, NAT gateways, endpoints, or workload-specific routing. Those controls will be defined by the application/deployment phase that needs them.
