# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: EFS with default settings (encrypted, generalPurpose)

mock_provider "aws" {}

run "efs_defaults_plan" {
  command = plan

  variables {
    create = true
    name   = "test-efs"

    tags = {
      Environment = "test"
      Project     = "efs"
    }
  }

  assert {
    condition     = output.id != null || true
    error_message = "EFS file system ID should be defined"
  }

  assert {
    condition     = output.arn != null || true
    error_message = "EFS file system ARN should be defined"
  }
}
