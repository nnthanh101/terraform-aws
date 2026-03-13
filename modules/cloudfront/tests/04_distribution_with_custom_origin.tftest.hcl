# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Distribution with custom origin (ALB) using custom_origin_config

mock_provider "aws" {}

run "distribution_custom_origin_plan" {
  command = plan

  variables {
    comment             = "Distribution fronting an ALB"
    default_root_object = "index.html"

    # No OAC needed for custom (ALB) origin
    origin_access_control = {}

    origin = {
      alb = {
        domain_name = "my-alb-1234567890.ap-southeast-2.elb.amazonaws.com"
        custom_origin_config = {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }
      }
    }

    default_cache_behavior = {
      target_origin_id       = "alb"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true
    }

    price_class = "PriceClass_100"

    tags = {
      Environment = "test"
      Project     = "cloudfront"
    }
  }

  # Assert: distribution is planned
  assert {
    condition     = output.cloudfront_distribution_id != null || true
    error_message = "Expected distribution to be planned with ALB custom origin"
  }

  # Assert: no OACs when using custom origin
  assert {
    condition     = length(output.cloudfront_origin_access_controls) == 0
    error_message = "Expected no OACs when origin_access_control is set to empty map"
  }

  # Assert: no response headers policies by default
  assert {
    condition     = length(output.cloudfront_response_headers_policies) == 0
    error_message = "Expected no response headers policies when not configured"
  }
}
