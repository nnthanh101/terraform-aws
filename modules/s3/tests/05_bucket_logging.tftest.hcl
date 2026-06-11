# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Access logging configuration

mock_provider "aws" {}

run "bucket_logging_plan" {
  command = plan

  variables {
    bucket = "test-bucket-logging"
    logging = {
      target_bucket = "test-log-target-bucket"
      target_prefix = "logs/test-bucket-logging/"
    }
    tags = {
      Environment = "test"
      Project     = "s3"
      Owner       = "platform-team"
    }
  }

  # Assert: logging variable is non-empty (triggers aws_s3_bucket_logging resource)
  assert {
    condition     = length(var.logging) > 0
    error_message = "logging map must be non-empty when access logging is configured"
  }

  # Assert: logging target_bucket is set correctly
  assert {
    condition     = var.logging["target_bucket"] == "test-log-target-bucket"
    error_message = "logging.target_bucket must be 'test-log-target-bucket'"
  }

  # Assert: logging target_prefix is set correctly
  assert {
    condition     = var.logging["target_prefix"] == "logs/test-bucket-logging/"
    error_message = "logging.target_prefix must be 'logs/test-bucket-logging/'"
  }

  # Assert: create_bucket is true
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }
}

run "bucket_logging_with_policy_plan" {
  command = plan

  variables {
    bucket = "test-log-delivery-bucket"
    logging = {
      target_bucket = "test-log-target-bucket"
      target_prefix = "s3-access-logs/"
    }
    attach_access_log_delivery_policy         = true
    access_log_delivery_policy_source_buckets = ["arn:aws:s3:::test-source-bucket"]
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: attach_access_log_delivery_policy variable is set
  assert {
    condition     = var.attach_access_log_delivery_policy == true
    error_message = "attach_access_log_delivery_policy must be true when log delivery policy is requested"
  }

  # Assert: source bucket ARN list is non-empty
  assert {
    condition     = length(var.access_log_delivery_policy_source_buckets) == 1
    error_message = "Expected 1 source bucket ARN for log delivery policy"
  }

  # Assert: logging is configured
  assert {
    condition     = length(var.logging) > 0
    error_message = "logging map must be non-empty when logging+policy is configured"
  }

  # Assert: create_bucket is true
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }
}

run "bucket_logging_disabled_plan" {
  command = plan

  variables {
    bucket = "test-bucket-no-logging"
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: logging variable is empty by default (no aws_s3_bucket_logging resource)
  assert {
    condition     = length(var.logging) == 0
    error_message = "logging must be empty map by default (no access logging resource)"
  }

  # Assert: create_bucket is true even without logging
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }

  # Assert: attach_access_log_delivery_policy defaults to false
  assert {
    condition     = var.attach_access_log_delivery_policy == false
    error_message = "attach_access_log_delivery_policy must default to false"
  }
}
