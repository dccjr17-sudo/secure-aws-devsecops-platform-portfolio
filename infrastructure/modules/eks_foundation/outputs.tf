output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "application_pod_identity_role_arn" {
  description = "IAM role associated only with the application Kubernetes service account."
  value       = aws_iam_role.application_pod.arn
}

output "nat_gateway_id" {
  description = "Single-AZ temporary-lab NAT gateway. Destroy the EKS foundation when the learning session ends."
  value       = aws_nat_gateway.eks_egress.id
}
