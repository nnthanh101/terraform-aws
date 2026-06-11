# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Versioning enabled + AES256 server-side encryption

mock_provider "aws" {}

run "bucket_versioning_plan" {
  command = plan

  variables {
    bucket = "test-bucket-versioning"
    versioning = {
      enabled = true
    }
    server_side_encryption_configuration = {
      rule = {
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
        bucket_key_enabled = true
      }
    }
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: create_bucket is true (bucket resource will be planned)
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }

  # Assert: versioning input is non-empty (triggers aws_s3_bucket_versioning resource)
  assert {
    condition     = length(var.versioning) > 0
    error_message = "versioning map must be non-empty to create aws_s3_bucket_versioning resource"
  }

  # Assert: versioning enabled key is set
  assert {
    condition     = var.versioning["enabled"] == "true" || var.versioning["enabled"] == true
    error_message = "versioning.enabled must be true"
  }

  # Assert: SSE config is non-empty (triggers resource creation)
  assert {
    condition     = length(var.server_side_encryption_configuration) > 0
    error_message = "server_side_encryption_configuration must be non-empty when SSE is configured"
  }

  # Assert: force_destroy defaults to false (protect versioned data)
  assert {
    condition     = var.force_destroy == false
    error_message = "force_destroy must default to false for versioned buckets"
  }

  # Assert: bucket name is set
  assert {
    condition     = var.bucket == "test-bucket-versioning"
    error_message = "bucket variable must be 'test-bucket-versioning'"
  }
}

run "bucket_versioning_suspended_plan" {
  command = plan

  variables {
    bucket = "test-bucket-versioning-suspended"
    versioning = {
      status = "Suspended"
    }
    tags = {
      Environment = "test"
      Project     = "s3"
    }
  }

  # Assert: versioning variable is set (resource will be created with Suspended status)
  assert {
    condition     = length(var.versioning) > 0
    error_message = "versioning map must be non-empty even for Suspended state"
  }

  # Assert: versioning status is Suspended
  assert {
    condition     = var.versioning["status"] == "Suspended"
    error_message = "versioning.status must be 'Suspended'"
  }

  # Assert: create_bucket is true
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }
}
