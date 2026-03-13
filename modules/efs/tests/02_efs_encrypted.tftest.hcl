# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: EFS with KMS CMK encryption (composition pattern)

mock_provider "aws" {}

run "efs_encrypted_plan" {
  command = plan

  variables {
    create    = true
    name      = "test-efs-encrypted"
    encrypted = true

    kms_key_arn = "arn:aws:kms:ap-southeast-2:123456789012:key/test-key-id"

    tags = {
      Environment = "test"
      Project     = "efs"
    }
  }

  assert {
    condition     = output.kms_key_arn != null
    error_message = "KMS key ARN output should be defined when encryption is enabled"
  }
}
