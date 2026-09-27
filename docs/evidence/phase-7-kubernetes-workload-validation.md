# Phase 7 Kubernetes workload validation evidence

## Scope

This record proves that the private application workload can run on the EKS
foundation without exposing an internet-facing application endpoint. It omits
account identifiers, cluster endpoints, image repository addresses, image
digests, node addresses, and IP ranges.

## Observed results

| Check | Observed result | Date | Notes |
| --- | --- | --- | --- |
| Pull-request checks | All seven required checks passed for the initial workload change. | 2026-09-13 | The standard application, Terraform, and security gates completed before merge. |
| EKS foundation | The cluster became `ACTIVE`; one managed node reported `Ready`. | 2026-09-13 | Both private and tightly restricted public API access were enabled for the lab. |
| Kubernetes system components | CoreDNS, the CNI, kube-proxy, and the Pod Identity agent were running. | 2026-09-13 | This establishes the required platform services before workload deployment. |
| Workload rollout | The `secure-platform` deployment reached `1/1` ready with one available replica. | 2026-09-13 | The deployment uses a pinned, immutable ECR image tag. |
| Pod hardening | The workload ran under an explicit non-root UID and GID with a restricted security profile. | 2026-09-13 | The source defines UID/GID `10001`, drops Linux capabilities, prevents privilege escalation, uses the runtime-default seccomp profile, and mounts a size-limited writable `/tmp`. |
| Private health check | `/health` returned `status: ok` through a local port-forward. | 2026-09-13 | The Kubernetes Service remains `ClusterIP`; no public load balancer or app endpoint was created. |
| Private application check | `/` returned the platform identifier and the default harmless message through the same local port-forward. | 2026-09-13 | No managed secret ID was configured for this initial workload proof. |

## Startup remediation

The first deployment exposed two configuration defects before the application
was usable: Kubernetes could not verify the image's named non-root user, and a
deployment script temporarily applied an invalid placeholder image. The image
now creates a stable numeric runtime identity and the script renders the
immutable ECR reference before applying the manifests. The corrected image
build, application tests, and Kubernetes client-side manifest validation all
succeeded before the successful rollout.

## Interview talking points

- I kept the application private by using a `ClusterIP` Service and validating it only through a local port-forward.
- I used an immutable ECR tag, explicit non-root UID/GID, restricted Pod Security settings, a minimal service account, and a default-deny network policy with only required egress paths.
- When the first rollout failed, I used Kubernetes pod status and logs to isolate the two configuration defects, corrected the source, and verified the resulting rollout rather than treating the initial failure as a pass.
