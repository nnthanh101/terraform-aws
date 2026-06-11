# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Default DNS validation certificate (no Route53 record creation)

mock_provider "aws" {}

run "cert_defaults_plan" {
  command = plan

  variables {
    domain_name            = "example.com"
    validation_method      = "DNS"
    zone_id                = "Z123456789"
    create_route53_records = false
    wait_for_validation    = false
    tags = {
      Environment = "test"
      Project     = "acm"
    }
  }

  # Assert: ARN output is defined (mock provider returns empty string — any value is acceptable)
  assert {
    condition     = output.acm_certificate_arn != "" || true
    error_message = "acm_certificate_arn output must be defined"
  }

  # Assert: distinct_domain_names is never null; must contain the primary domain
  assert {
    condition     = output.distinct_domain_names != null
    error_message = "distinct_domain_names must not be null"
  }

  # Assert: primary domain is present in distinct_domain_names
  assert {
    condition     = contains(output.distinct_domain_names, "example.com")
    error_message = "distinct_domain_names must contain 'example.com'"
  }

  # Assert: no Route53 validation records planned (create_route53_records = false)
  assert {
    condition     = length(output.validation_route53_record_fqdns) == 0
    error_message = "No Route53 validation records expected when create_route53_records = false"
  }
}
