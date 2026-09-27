data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"

  # Including the account ID makes this globally unique without putting an
  # account-specific value in a variable file. The shortened project portion
  # keeps even the longest permitted project/environment pair below S3's
  # 63-character bucket-name limit.
  audit_bucket_name = "${substr(var.project_name, 0, 24)}-${var.environment}-audit-${data.aws_caller_identity.current.account_id}"
  audit_trail_name  = "${local.resource_prefix}-audit"
  audit_log_prefix  = "cloudtrail"
  audit_trail_arn   = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.audit_trail_name}"

  common_tags = merge(var.tags, {
    Component = "security-observability"
    Phase     = "6-secrets-detection"
  })
}

# One customer-managed key is intentionally shared by the new managed secret
# and CloudTrail. Existing low-cost lab resources retain their documented
# AWS-managed encryption choice rather than being changed opportunistically.
data "aws_iam_policy_document" "security_key" {
  statement {
    sid       = "AllowAccountRootAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudTrailToEncryptAuditLogs"
    effect    = "Allow"
    actions   = ["kms:DescribeKey", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.audit_trail_arn]
    }
  }
}

resource "aws_kms_key" "security" {
  description             = "Encrypts Phase 6 ${local.resource_prefix} secrets and CloudTrail audit logs."
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.security_key.json

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-security"
  })
}

resource "aws_kms_alias" "security" {
  name          = "alias/${local.resource_prefix}-security"
  target_key_id = aws_kms_key.security.key_id
}

# Terraform creates metadata only. Do not add aws_secretsmanager_secret_version
# here: a secret value in Terraform would be stored in state.
resource "aws_secretsmanager_secret" "application_configuration" {
  name                    = "${local.resource_prefix}/application-configuration"
  description             = "Runtime configuration for ${local.resource_prefix}; value is added outside Terraform."
  kms_key_id              = aws_kms_key.security.arn
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-application-configuration"
  })
}

# This policy is deliberately unattached: the platform has no workload identity
# yet. Phase 7 will attach this exact policy to the chosen runtime identity,
# instead of creating an unused broad EC2/ECS trust relationship now.
data "aws_iam_policy_document" "runtime_configuration_read" {
  statement {
    sid       = "ReadOnlyTheApplicationConfigurationSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.application_configuration.arn]
  }

  statement {
    sid       = "DecryptOnlyThroughSecretsManagerForThisSecret"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.security.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:secretsmanager:arn"
      values   = [aws_secretsmanager_secret.application_configuration.arn]
    }
  }
}

resource "aws_iam_policy" "runtime_configuration_read" {
  name        = "${local.resource_prefix}-runtime-configuration-read"
  description = "Unattached least-privilege policy for the Phase 7 application runtime identity."
  policy      = data.aws_iam_policy_document.runtime_configuration_read.json

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-runtime-configuration-read"
  })
}

resource "aws_s3_bucket" "audit_logs" {
  bucket        = local.audit_bucket_name
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = local.audit_bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.security.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "expire-lab-audit-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.audit_log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.audit_log_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "audit_log_bucket" {
  statement {
    sid       = "AllowCloudTrailToCheckBucketAcl"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit_logs.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.audit_trail_arn]
    }
  }

  statement {
    sid       = "AllowCloudTrailToWriteOnlyThisTrailsLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit_logs.arn}/${local.audit_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.audit_trail_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.audit_logs.arn, "${aws_s3_bucket.audit_logs.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = data.aws_iam_policy_document.audit_log_bucket.json
}

# The trail records management events across all regions. Deliberately exclude
# data-event selectors and CloudWatch Logs delivery for this low-cost lab;
# both expand ingest/retention costs without a workload investigation need yet.
resource "aws_cloudtrail" "audit" {
  name                          = local.audit_trail_name
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  s3_key_prefix                 = local.audit_log_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.security.arn

  depends_on = [aws_s3_bucket_policy.audit_logs]

  tags = merge(local.common_tags, {
    Name = local.audit_trail_name
  })
}

# These services have free trials but can become billable. Their default is
# false, so an apply cannot silently enable them. See the Phase 6 runbook
# before explicitly opting in for controlled-finding validation.
resource "aws_guardduty_detector" "this" {
  count = var.enable_threat_detection_services ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "SIX_HOURS"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-guardduty"
  })
}

resource "aws_securityhub_account" "this" {
  count = var.enable_threat_detection_services ? 1 : 0

  # Security Hub standards rely on AWS Config and can increase the lab's
  # resource footprint. Phase 6 uses Security Hub as a detection landing zone;
  # standards are a later, explicit decision.
  enable_default_standards = false

  depends_on = [aws_guardduty_detector.this]
}
