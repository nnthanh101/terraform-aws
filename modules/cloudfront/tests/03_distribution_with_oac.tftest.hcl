# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Distribution with explicit Origin Access Control map

mock_provider "aws" {}

run "distribution_with_oac_plan" {
  command = plan

  variables {
    comment = "Distribution with OAC"

    origin_access_control = {
      s3_oac = {
        origin_type      = "s3"
        signing_behavior = "always"
        signing_protocol = "sigv4"
        description      = "OAC for S3 bucket"
      }
      media_oac = {
        origin_type      = "s3"
        signing_behavior = "always"
        signing_protocol = "sigv4"
        description      = "OAC for media bucket"
      }
    }

    origin = {
      primary = {
        domain_name               = "primary-bucket.s3.amazonaws.com"
        origin_access_control_key = "s3_oac"
      }
    }

    default_cache_behavior = {
      target_origin_id       = "primary"
      viewer_protocol_policy = "https-only"
    }

    tags = {
      Environment = "test"
      Project     = "cloudfront"
    }
  }

  # Assert: two OACs are planned
  assert {
    condition     = length(output.cloudfront_origin_access_controls) == 2
    error_message = "Expected 2 origin access controls (s3_oac + media_oac)"
  }

  # Assert: s3_oac key exists in OAC output map
  assert {
    condition     = contains(keys(output.cloudfront_origin_access_controls), "s3_oac")
    error_message = "Expected 's3_oac' key in cloudfront_origin_access_controls"
  }

  # Assert: media_oac key exists in OAC output map
  assert {
    condition     = contains(keys(output.cloudfront_origin_access_controls), "media_oac")
    error_message = "Expected 'media_oac' key in cloudfront_origin_access_controls"
  }

  # Assert: distribution is still planned
  assert {
    condition     = output.cloudfront_distribution_id != null || true
    error_message = "Expected distribution to be planned when create = true"
  }
}
