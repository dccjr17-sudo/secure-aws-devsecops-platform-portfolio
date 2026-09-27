locals {
  # Phase 1 is intentionally a two-AZ foundation. Expand this deliberately in
  # a future architecture decision rather than adding subnets by accident.
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "network" {
  source = "../../modules/network"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zones      = local.availability_zones
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  flow_log_retention_days = var.flow_log_retention_days

  tags = {
    DataClassification = "Lab"
    Owner              = "Portfolio"
  }
}

module "container_registry" {
  source = "../../modules/registry"

  project_name         = var.project_name
  environment          = var.environment
  retained_image_count = 10

  tags = {
    DataClassification = "Lab"
    Owner              = "Portfolio"
  }
}

module "github_actions_oidc" {
  source = "../../modules/github_actions_oidc"

  project_name = var.project_name
  environment  = var.environment

  # GitHub repositories created after July 15, 2026 use an immutable OIDC
  # subject format. This exact subject permits only the main branch of this
  # repository to request the publishing role.
  github_oidc_subject = "repo:dccjr17-sudo@233174618/secure-aws-devsecops-platform@1359570339:ref:refs/heads/main"
  ecr_repository_arn  = module.container_registry.repository_arn

  tags = {
    DataClassification = "Lab"
    Owner              = "Portfolio"
  }
}

module "security_observability" {
  source = "../../modules/security_observability"

  project_name                     = var.project_name
  environment                      = var.environment
  audit_log_retention_days         = var.audit_log_retention_days
  secret_recovery_window_in_days   = var.secret_recovery_window_in_days
  kms_key_deletion_window_in_days  = var.kms_key_deletion_window_in_days
  enable_threat_detection_services = var.enable_threat_detection_services

  tags = {
    DataClassification = "Lab"
    Owner              = "Portfolio"
  }
}

# EKS is deliberately opt-in because a control plane, worker node, NAT
# gateway, and public IPv4 address can accrue charges while they exist.
# Set enable_eks_foundation = true only in the ignored local terraform.tfvars
# after reviewing a plan and selecting a trusted public CIDR for kubectl access.
module "eks_foundation" {
  count  = var.enable_eks_foundation ? 1 : 0
  source = "../../modules/eks_foundation"

  project_name                     = var.project_name
  environment                      = var.environment
  kubernetes_version               = var.eks_kubernetes_version
  vpc_id                           = module.network.vpc_id
  public_subnet_ids                = module.network.public_subnet_ids
  private_subnet_ids               = module.network.private_subnet_ids
  private_route_table_ids          = module.network.private_application_route_table_ids
  cluster_public_access_cidrs      = var.eks_cluster_public_access_cidrs
  control_plane_log_retention_days = var.eks_control_plane_log_retention_days
  runtime_configuration_policy_arn = module.security_observability.runtime_configuration_read_policy_arn

  tags = {
    DataClassification = "Lab"
    Owner              = "Portfolio"
  }

  depends_on = [module.network, module.security_observability]
}
