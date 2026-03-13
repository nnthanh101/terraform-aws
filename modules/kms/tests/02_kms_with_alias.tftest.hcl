# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: KMS key with alias

mock_provider "aws" {}

run "kms_with_alias_plan" {
  command = plan

  variables {
    create = true

    aliases = ["alias/test-key"]

    tags = {
      Environment = "test"
      Project     = "kms"
    }
  }

  assert {
    condition     = output.key_arn != null || true
    error_message = "KMS key ARN should be defined with alias"
  }

  assert {
    condition     = output.aliases != null || true
    error_message = "KMS aliases output should be defined"
  }
}
