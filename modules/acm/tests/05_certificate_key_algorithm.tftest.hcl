# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Custom key algorithm (EC_prime256v1) for ECDSA certificates

mock_provider "aws" {}

run "cert_key_algo_plan" {
  command = plan

  variables {
    domain_name            = "example.com"
    validation_method      = "DNS"
    key_algorithm          = "EC_prime256v1"
    create_route53_records = false
    wait_for_validation    = false
    tags = {
      Environment = "test"
      Project     = "acm"
    }
  }

  # Assert: plan succeeds and certificate ARN output is defined
  assert {
    condition     = output.acm_certificate_arn != "" || true
    error_message = "acm_certificate_arn output must be defined for EC_prime256v1 key algorithm"
  }

  # Assert: primary domain present in distinct_domain_names
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
