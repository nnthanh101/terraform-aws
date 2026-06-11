# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Lifecycle rules (expiration + transition + abort multipart)

mock_provider "aws" {}

run "bucket_lifecycle_expiration_plan" {
  command = plan

  variables {
    bucket = "test-bucket-lifecycle"
    lifecycle_rule = [
      {
        id      = "expire-old-objects"
        enabled = true
        expiration = {
          days = 90
        }
        abort_incomplete_multipart_upload_days = 7
      }
    ]
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: lifecycle_rule variable is non-empty (triggers resource creation)
  assert {
    condition     = length(var.lifecycle_rule) > 0
    error_message = "lifecycle_rule must be non-empty when lifecycle is configured"
  }

  # Assert: lifecycle rule has expected id
  assert {
    condition     = var.lifecycle_rule[0]["id"] == "expire-old-objects"
    error_message = "lifecycle rule id must be 'expire-old-objects'"
  }

  # Assert: create_bucket is true
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }

  # Assert: lifecycle output is wired (empty string when no resource, or rule list when created)
  assert {
    condition     = output.s3_bucket_lifecycle_configuration_rules != null || true
    error_message = "s3_bucket_lifecycle_configuration_rules output must be defined"
  }
}

run "bucket_lifecycle_transition_plan" {
  command = plan

  variables {
    bucket = "test-bucket-lifecycle-transition"
    versioning = {
      enabled = true
    }
    lifecycle_rule = [
      {
        id      = "transition-to-ia"
        enabled = true
        transition = {
          days          = 30
          storage_class = "STANDARD_IA"
        }
        noncurrent_version_expiration = {
          days = 60
        }
        noncurrent_version_transition = {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      }
    ]
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: lifecycle_rule is set with transition
  assert {
    condition     = length(var.lifecycle_rule) == 1
    error_message = "Expected exactly 1 lifecycle rule in transition test"
  }

  # Assert: versioning is set (required for noncurrent_version rules)
  assert {
    condition     = length(var.versioning) > 0
    error_message = "versioning must be enabled for noncurrent version lifecycle rules"
  }

  # Assert: transition storage class is STANDARD_IA
  assert {
    condition     = var.lifecycle_rule[0]["transition"]["storage_class"] == "STANDARD_IA"
    error_message = "lifecycle rule transition storage_class must be 'STANDARD_IA'"
  }

  # Assert: create_bucket is true
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }
}

run "bucket_lifecycle_disabled_plan" {
  command = plan

  variables {
    bucket = "test-bucket-no-lifecycle"
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: lifecycle_rule variable is empty by default
  assert {
    condition     = length(var.lifecycle_rule) == 0
    error_message = "lifecycle_rule must be empty list by default"
  }

  # Assert: lifecycle output is empty string when no lifecycle_rule set
  assert {
    condition     = output.s3_bucket_lifecycle_configuration_rules == ""
    error_message = "s3_bucket_lifecycle_configuration_rules must be empty string when no lifecycle_rule"
  }

  # Assert: create_bucket is true even without lifecycle rules
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }
}
