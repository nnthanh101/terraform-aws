# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: create_certificate = false produces no ACM resources (kill-switch)

mock_provider "aws" {}

run "cert_disabled_plan" {
  command = plan

  variables {
    create_certificate = false
  }

  # Assert: no certificate ARN when create_certificate = false
  # try() in outputs.tf falls through to the "" default when aws_acm_certificate.this is empty
  assert {
    condition     = output.acm_certificate_arn == ""
    error_message = "Expected empty ARN when create_certificate = false"
  }

  # Assert: no certificate status when create_certificate = false
  assert {
    condition     = output.acm_certificate_status == ""
    error_message = "Expected empty status when create_certificate = false"
  }

  # Assert: no Route53 validation records planned
  assert {
    condition     = length(output.validation_route53_record_fqdns) == 0
    error_message = "Expected no Route53 validation records when create_certificate = false"
  }

  # Assert: domain_validation_options is empty
  assert {
    condition     = length(output.acm_certificate_domain_validation_options) == 0
    error_message = "Expected no domain_validation_options when create_certificate = false"
  }
}
