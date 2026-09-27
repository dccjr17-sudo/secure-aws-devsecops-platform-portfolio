locals {
  common_tags = merge(var.tags, {
    Component = "github-actions-oidc"
    Phase     = "4-cicd"
  })
}

# GitHub is a shared OIDC identity provider in an AWS account. This project
# creates it only after verifying that no provider already exists in the lab
# account. The GitHub provider uses AWS-managed root CAs, so no thumbprint is
# configured here.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  tags = merge(local.common_tags, {
    Name = "github-actions"
  })
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "AllowOnlyThisRepositoryMainBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    # Both claims are required. The immutable subject value makes the trust
    # relationship resilient to a future repository rename or transfer.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr_publish" {
  name                 = "github-${var.project_name}-${var.environment}-ecr-publish"
  description          = "Allows the trusted GitHub Actions workflow to publish one project's ECR images."
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600

  tags = merge(local.common_tags, {
    Name = "github-${var.project_name}-${var.environment}-ecr-publish"
  })
}

data "aws_iam_policy_document" "github_actions_ecr_publish" {
  statement {
    sid       = "RequestEcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PublishOnlyToProjectRepository"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr_publish" {
  name   = "publish-project-ecr-image"
  role   = aws_iam_role.github_actions_ecr_publish.id
  policy = data.aws_iam_policy_document.github_actions_ecr_publish.json
}
