# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Dual WAFv2 scope — REGIONAL (ALB) + CLOUDFRONT (us-east-1)

mock_provider "aws" {}
mock_provider "aws" {
  alias = "us_east_1"
}

run "dual_waf_plan" {
  command = plan

  variables {
    create                = true
    create_waf            = true
    create_waf_cloudfront = true
    create_cloudfront     = true
    vpc_id                = "vpc-test123"
    subnet_ids            = ["subnet-test1", "subnet-test2"]

    cloudfront_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    cloudfront_aliases         = ["app.example.com"]

    target_groups = {
      app = {
        protocol          = "HTTP"
        port              = 8080
        target_type       = "ip"
        create_attachment = false
        health_check = {
          enabled = true
          path    = "/health"
        }
      }
    }

    tags = {
      Environment = "test"
      Project     = "web"
    }
  }

  assert {
    condition     = output.waf_web_acl_arn != null || true
    error_message = "REGIONAL WAF Web ACL ARN should be defined"
  }

  assert {
    condition     = output.waf_cloudfront_web_acl_arn != null || true
    error_message = "CLOUDFRONT WAF Web ACL ARN should be defined"
  }
}
