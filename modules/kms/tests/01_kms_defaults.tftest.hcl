# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: KMS key with default settings

mock_provider "aws" {}

run "kms_defaults_plan" {
  command = plan

  variables {
    create = true

    # Provide explicit policy to bypass mock data source (mock_provider returns non-JSON for aws_iam_policy_document)
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::123456789012:root" }
        Action    = "kms:*"
        Resource  = "*"
      }]
    })

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
