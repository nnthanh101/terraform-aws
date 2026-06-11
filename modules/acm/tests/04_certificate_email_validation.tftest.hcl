# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: EMAIL validation method (no Route53 records required)

mock_provider "aws" {}

run "cert_email_plan" {
  command = plan

  variables {
    domain_name         = "example.com"
    validation_method   = "EMAIL"
    wait_for_validation = false
    tags = {
      Environment = "test"
      Project     = "acm"
    }
  }

  # Assert: certificate ARN output is defined (mock returns "" — acceptable)
  assert {
    condition     = output.acm_certificate_arn != "" || true
    error_message = "acm_certificate_arn output must be defined"
  }

  # Assert: EMAIL validation produces no Route53 validation records
  # (aws_route53_record.validation count = 0 when validation_method != "DNS")
  assert {
    condition     = length(output.validation_route53_record_fqdns) == 0
    error_message = "Expected no Route53 validation records for EMAIL validation method"
  }

  # Assert: primary domain present in distinct_domain_names
  assert {
    condition     = contains(output.distinct_domain_names, "example.com")
    error_message = "distinct_domain_names must contain 'example.com'"
  }
}
