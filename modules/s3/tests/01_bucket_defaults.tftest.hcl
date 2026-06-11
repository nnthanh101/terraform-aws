# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Default bucket with minimal config (name + tags)

mock_provider "aws" {}

run "bucket_defaults_plan" {
  command = plan

  variables {
    bucket = "test-bucket-defaults"
    tags = {
      Environment = "test"
      Project     = "s3"
      Owner       = "platform-team"
      CostCenter  = "engineering"
    }
  }

  # Assert: create_bucket defaults to true (bucket resource will be planned)
  assert {
    condition     = var.create_bucket == true
    error_message = "create_bucket must default to true"
  }

  # Assert: bucket name is passed through correctly
  assert {
    condition     = var.bucket == "test-bucket-defaults"
    error_message = "bucket variable must be 'test-bucket-defaults'"
  }

  # Assert: tags map has expected keys
  assert {
    condition     = length(var.tags) == 4
    error_message = "Expected 4 tags (Environment, Project, Owner, CostCenter)"
  }

  # Assert: public access block defaults are enforced (block_public_acls=true)
  assert {
    condition     = var.block_public_acls == true
    error_message = "block_public_acls must default to true (security baseline)"
  }

  # Assert: block_public_policy defaults to true
  assert {
    condition     = var.block_public_policy == true
    error_message = "block_public_policy must default to true (security baseline)"
  }

  # Assert: ignore_public_acls defaults to true
  assert {
    condition     = var.ignore_public_acls == true
    error_message = "ignore_public_acls must default to true (security baseline)"
  }

  # Assert: restrict_public_buckets defaults to true
  assert {
    condition     = var.restrict_public_buckets == true
    error_message = "restrict_public_buckets must default to true (security baseline)"
  }

  # Assert: force_destroy defaults to false (protect data)
  assert {
    condition     = var.force_destroy == false
    error_message = "force_destroy must default to false"
  }

  # Assert: object_lock_enabled defaults to false
  assert {
    condition     = var.object_lock_enabled == false
    error_message = "object_lock_enabled must default to false"
  }
}
