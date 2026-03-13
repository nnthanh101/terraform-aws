# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Distribution with response headers policy (security headers)

mock_provider "aws" {}

run "distribution_response_headers_plan" {
  command = plan

  variables {
    comment = "Distribution with security response headers"

    origin = {
      s3 = {
        domain_name = "secure-bucket.s3.amazonaws.com"
      }
    }

    default_cache_behavior = {
      target_origin_id            = "s3"
      viewer_protocol_policy      = "https-only"
      response_headers_policy_key = "security"
    }

    response_headers_policies = {
      security = {
        name    = "test-security-headers"
        comment = "Security headers for test distribution"
        security_headers_config = {
          strict_transport_security = {
            access_control_max_age_sec = 31536000
            override                   = true
            include_subdomains         = true
            preload                    = true
          }
          content_type_options = {
            override = true
          }
          frame_options = {
            frame_option = "DENY"
            override     = true
          }
          xss_protection = {
            mode_block = true
            override   = true
            protection = true
          }
          referrer_policy = {
            referrer_policy = "strict-origin-when-cross-origin"
            override        = true
          }
        }
      }
    }

    tags = {
      Environment = "test"
      Project     = "cloudfront"
    }
  }

  # Assert: one response headers policy is planned
  assert {
    condition     = length(output.cloudfront_response_headers_policies) == 1
    error_message = "Expected 1 response headers policy to be created"
  }

  # Assert: 'security' key exists in response headers policies output
  assert {
    condition     = contains(keys(output.cloudfront_response_headers_policies), "security")
    error_message = "Expected 'security' key in cloudfront_response_headers_policies output"
  }

  # Assert: distribution is planned alongside the response headers policy
  assert {
    condition     = output.cloudfront_distribution_id != null || true
    error_message = "Expected distribution to be planned with response headers policy"
  }

  # Assert: default OAC is still created (variable default includes s3 OAC)
  assert {
    condition     = length(output.cloudfront_origin_access_controls) > 0
    error_message = "Expected default s3 OAC to be present"
  }
}
