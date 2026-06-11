# Foundation module — real AWS resources, LocalStack Community-compatible.
# Resources: media S3, Secrets Manager x4, SQS event bus + DLQ, SNS topic + subscription.
#
# State bucket excluded: provisioned by a separate bootstrap root to avoid
# the self-referential deadlock (bootstrap owns genesis; foundation owns workload).
#
# No CloudWatch log groups: use AWS Managed Prometheus + Grafana for vendor-neutral observability.
#
# Tags: all resources inherit provider.default_tags; per-resource overrides set Service tag.

locals {
  prefix = "${var.name_prefix}-${var.environment}"
}

# ---------------------------------------------------------------------------
# S3: Media bucket
# Service override = storefront (media assets for the frontend tier)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "media" {
  bucket = "${local.prefix}-media"

  tags = merge({ Service = "storefront" }, var.additional_tags)
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Secrets Manager: application runtime secrets
# Service override = backend (all secrets serve the backend service)
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${local.prefix}/DATABASE_URL"
  recovery_window_in_days = var.secret_recovery_window

  tags = merge({ Service = "backend" }, var.additional_tags)
}

resource "aws_secretsmanager_secret" "redis_url" {
  name                    = "${local.prefix}/REDIS_URL"
  recovery_window_in_days = var.secret_recovery_window

  tags = merge({ Service = "backend" }, var.additional_tags)
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${local.prefix}/JWT_SECRET"
  recovery_window_in_days = var.secret_recovery_window

  tags = merge({ Service = "backend" }, var.additional_tags)
}

resource "aws_secretsmanager_secret" "cookie_secret" {
  name                    = "${local.prefix}/COOKIE_SECRET"
  recovery_window_in_days = var.secret_recovery_window

  tags = merge({ Service = "backend" }, var.additional_tags)
}

# ---------------------------------------------------------------------------
# SQS: Dead-letter queue for event bus queue
# sqs_managed_sse_enabled satisfies CKV_AWS_27 without KMS CMK (LocalStack-compatible).
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "events_dlq" {
  name                    = "${local.prefix}-events-dlq"
  sqs_managed_sse_enabled = true

  tags = merge({ Service = "async" }, var.additional_tags)
}

# ---------------------------------------------------------------------------
# SQS: Application event bus queue (with redrive to DLQ)
# Service override = async (messaging tier)
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "events" {
  name                    = "${local.prefix}-events"
  sqs_managed_sse_enabled = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge({ Service = "async" }, var.additional_tags)
}

# ---------------------------------------------------------------------------
# SNS: Application event bus topic
# kms_master_key_id = "alias/aws/sns" satisfies CKV_AWS_26 (LocalStack-compatible).
# Service override = async
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "events" {
  name              = "${local.prefix}-events"
  kms_master_key_id = "alias/aws/sns"

  tags = merge({ Service = "async" }, var.additional_tags)
}

resource "aws_sns_topic_subscription" "events_to_sqs" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.events.arn
}
