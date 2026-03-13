# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: create = false produces no distribution (kill-switch)

mock_provider "aws" {}

run "distribution_disabled_plan" {
  command = plan

  variables {
    create = false

    origin = {
      s3 = {
        domain_name = "mybucket.s3.amazonaws.com"
      }
    }

    default_cache_behavior = {
      target_origin_id       = "s3"
      viewer_protocol_policy = "https-only"
    }
  }

  # Assert: no distribution ID when create = false
  assert {
    condition     = output.cloudfront_distribution_id == null
    error_message = "Expected cloudfront_distribution_id to be null when create = false"
  }

  # Assert: no distribution ARN when create = false
  assert {
    condition     = output.cloudfront_distribution_arn == null
    error_message = "Expected cloudfront_distribution_arn to be null when create = false"
  }

  # Assert: no domain name when create = false
  assert {
    condition     = output.cloudfront_distribution_domain_name == null
    error_message = "Expected cloudfront_distribution_domain_name to be null when create = false"
  }

  # Assert: no monitoring subscription when create = false
  assert {
    condition     = output.cloudfront_monitoring_subscription_id == null
    error_message = "Expected no monitoring subscription when create = false"
  }
}
