data "aws_partition" "current" {}

locals {
  resource_prefix             = "${var.project_name}-${var.environment}"
  cluster_name                = local.resource_prefix
  application_namespace       = "application"
  application_service_account = "secure-platform"

  common_tags = merge(var.tags, {
    Component = "eks-foundation"
    Phase     = "7-kubernetes"
  })
}

# Private worker nodes require outbound access to pull ECR images, resolve AWS
# endpoints, and retrieve runtime configuration. One NAT gateway is an explicit
# cost/resilience trade-off for this short-lived learning environment; a
# production topology would use egress in each AZ or private endpoints.
resource "aws_eip" "eks_egress" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-eks-egress"
  })
}

resource "aws_nat_gateway" "eks_egress" {
  allocation_id = aws_eip.eks_egress.id
  subnet_id     = var.public_subnet_ids[0]

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-eks-egress"
  })
}

resource "aws_route" "private_eks_egress" {
  for_each = toset(var.private_route_table_ids)

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_egress.id
}

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "eks-${local.resource_prefix}-cluster"
  description        = "Amazon EKS control-plane role for ${local.resource_prefix}."
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(local.common_tags, {
    Name = "eks-${local.resource_prefix}-cluster"
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "eks-${local.resource_prefix}-node"
  description        = "Managed EKS node role for ${local.resource_prefix}; it has no application secret permissions."
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(local.common_tags, {
    Name = "eks-${local.resource_prefix}-node"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_pull" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# Pre-creating this group lets Terraform control retention before EKS sends
# control-plane API, audit, authenticator, controller, and scheduler logs.
resource "aws_cloudwatch_log_group" "control_plane" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.control_plane_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-eks-control-plane"
  })
}

# Kubernetes 1.28+ has EKS-managed envelope encryption by default. This lab
# intentionally uses that AWS-owned key rather than adding another paid KMS key
# or coupling the cluster's lifecycle to the Phase 6 key.
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_public_access_cidrs
  }

  depends_on = [
    aws_cloudwatch_log_group.control_plane,
    aws_iam_role_policy_attachment.cluster,
    aws_route.private_eks_egress,
  ]

  tags = merge(local.common_tags, {
    Name = local.cluster_name
  })
}

# Manage core add-ons explicitly so their lifecycle is visible in Terraform.
# The VPC CNI is installed before worker nodes need it; the remaining add-ons
# wait for a node to be available.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_node_group" "application" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "application"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_pull,
  ]

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-application"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.application]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.application]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.application]
}

# The pod identity role, not the EC2 node role, receives the Phase 6 secret
# read policy. EKS can therefore hand it only to the named service account.
data "aws_iam_policy_document" "application_pod_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "application_pod" {
  name               = "eks-${local.resource_prefix}-application"
  description        = "Pod Identity role for only the ${local.application_namespace}/${local.application_service_account} workload."
  assume_role_policy = data.aws_iam_policy_document.application_pod_assume_role.json

  tags = merge(local.common_tags, {
    Name = "eks-${local.resource_prefix}-application"
  })
}

resource "aws_iam_role_policy_attachment" "application_runtime_configuration" {
  role       = aws_iam_role.application_pod.name
  policy_arn = var.runtime_configuration_policy_arn
}

resource "aws_eks_pod_identity_association" "application" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = local.application_namespace
  service_account = local.application_service_account
  role_arn        = aws_iam_role.application_pod.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.application_runtime_configuration,
  ]
}
