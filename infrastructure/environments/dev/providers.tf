provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Phase       = "1-foundation"
      Repository  = "secure-aws-devsecops-platform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
