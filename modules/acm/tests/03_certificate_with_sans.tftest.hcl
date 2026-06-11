# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Certificate with Subject Alternative Names (SANs)

mock_provider "aws" {}

run "cert_with_sans_plan" {
  command = plan

  variables {
    domain_name               = "example.com"
    subject_alternative_names = ["*.example.com", "api.example.com"]
    validation_method         = "DNS"
    zone_id                   = "Z123456789"
    create_route53_records    = false
    wait_for_validation       = false
    tags = {
      Environment = "test"
      Project     = "acm"
    }
  }

  # Assert: primary domain present in distinct_domain_names
  assert {
    condition     = contains(output.distinct_domain_names, "example.com")
    error_message = "distinct_domain_names must contain primary domain 'example.com'"
  }

  # Assert: wildcard SAN is de-wildcarded and present (replace("*.", "") → "example.com" deduped)
  # api.example.com must be present as a distinct domain
  assert {
    condition     = contains(output.distinct_domain_names, "api.example.com")
    error_message = "distinct_domain_names must contain SAN 'api.example.com'"
  }

  # Assert: at least 2 distinct domain names (example.com + api.example.com; wildcard deduped)
  assert {
    condition     = length(output.distinct_domain_names) >= 2
    error_message = "Expected at least 2 distinct_domain_names (primary + api SAN)"
  }

  # Assert: no Route53 records planned (create_route53_records = false)
  assert {
    condition     = length(output.validation_route53_record_fqdns) == 0
    error_message = "No Route53 validation records expected when create_route53_records = false"
  }
}
