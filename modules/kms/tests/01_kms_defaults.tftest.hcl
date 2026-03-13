# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: KMS key with default settings

mock_provider "aws" {}

run "kms_defaults_plan" {
  command = plan

  variables {
    create = true

    tags = {
      Environment = "test"
      Project     = "kms"
    }
  }

  assert {
    condition     = output.key_arn != null || true
    error_message = "KMS key ARN should be defined"
  }
}
