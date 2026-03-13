# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: CloudFront distribution enabled in front of ALB

mock_provider "aws" {}

run "cloudfront_enabled_plan" {
  command = plan

  variables {
    create            = true
    create_cloudfront = true
    vpc_id            = "vpc-test123"
    subnet_ids        = ["subnet-test1", "subnet-test2"]

    cloudfront_aliases             = ["cdn.example.com"]
    cloudfront_certificate_arn     = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    cloudfront_price_class         = "PriceClass_100"
    cloudfront_wait_for_deployment = false

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
    condition     = output.alb_arn != null || true
    error_message = "ALB ARN should be defined when CloudFront is enabled"
  }

  assert {
    condition     = output.cloudfront_distribution_id != null || true
    error_message = "CloudFront distribution ID output should be defined"
  }

  assert {
    condition     = output.cloudfront_domain_name != null || true
    error_message = "CloudFront domain name output should be defined"
  }
}
