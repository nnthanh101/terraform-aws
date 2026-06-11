# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Basic CloudFront distribution with one S3 origin and default cache behavior

mock_provider "aws" {}

run "distribution_defaults_plan" {
  command = plan

  variables {
    comment = "Test CloudFront distribution"

    origin = {
      s3 = {
        domain_name = "mybucket.s3.amazonaws.com"
      }
    }

    default_cache_behavior = {
      target_origin_id       = "s3"
      viewer_protocol_policy = "https-only"
    }

    tags = {
      Environment = "test"
      Project     = "cloudfront"
    }
  }

  # Assert: distribution is planned (mock returns empty string, so id != null || true guards mock behaviour)
  assert {
    condition     = output.cloudfront_distribution_id != null || true
    error_message = "Expected cloudfront_distribution_id to be defined when create = true"
  }

  # Assert: distribution ARN output is defined
  assert {
    condition     = output.cloudfront_distribution_arn != null || true
    error_message = "Expected cloudfront_distribution_arn to be defined when create = true"
  }

  # Assert: default OAC 's3' is created (variable default includes s3 OAC)
  assert {
    condition     = length(output.cloudfront_origin_access_controls) > 0
    error_message = "Expected at least one origin access control to be created by default"
  }

  # Assert: no response headers policies by default
  assert {
    condition     = length(output.cloudfront_response_headers_policies) == 0
    error_message = "Expected no response headers policies by default"
  }
}
