# Tier 1 snapshot/plan test — mock_provider, no real AWS credentials required.
# Validates: all expected resources planned; naming prefix applied correctly.

mock_provider "aws" {}

run "plan_foundation_resources" {
  command = plan

  variables {
    environment            = "dev"
    name_prefix            = "myapp"
    secret_recovery_window = 0
  }

  assert {
    condition     = aws_s3_bucket.media.bucket == "myapp-dev-media"
    error_message = "Expected media bucket name to be '{name_prefix}-{environment}-media'."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.media.block_public_acls == true
    error_message = "Expected media bucket to block public ACLs."
  }

  assert {
    condition     = aws_sqs_queue.events.name == "myapp-dev-events"
    error_message = "Expected event bus queue name to be '{name_prefix}-{environment}-events'."
  }

  assert {
    condition     = aws_sqs_queue.events_dlq.name == "myapp-dev-events-dlq"
    error_message = "Expected DLQ name to be '{name_prefix}-{environment}-events-dlq'."
  }

  assert {
    condition     = aws_sns_topic.events.name == "myapp-dev-events"
    error_message = "Expected SNS topic name to be '{name_prefix}-{environment}-events'."
  }

  assert {
    condition     = length(aws_secretsmanager_secret.database_url.name) > 0
    error_message = "Expected DATABASE_URL secret to be planned."
  }

  assert {
    condition     = length(aws_secretsmanager_secret.redis_url.name) > 0
    error_message = "Expected REDIS_URL secret to be planned."
  }
}

run "plan_default_name_prefix" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = aws_s3_bucket.media.bucket == "app-staging-media"
    error_message = "Expected default name_prefix 'app' to produce 'app-staging-media' bucket."
  }
}
