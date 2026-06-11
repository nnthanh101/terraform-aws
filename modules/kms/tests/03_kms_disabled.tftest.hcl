# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: KMS module disabled (create = false)

mock_provider "aws" {}

run "kms_disabled_plan" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.key_arn == null || output.key_arn == ""
    error_message = "KMS key ARN should be null/empty when create = false"
  }
}
