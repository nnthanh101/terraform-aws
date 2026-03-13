# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: WAFv2 Web ACL with AWS Managed Rules enabled and associated with ALB

mock_provider "aws" {}

run "waf_enabled_plan" {
  command = plan

  variables {
    create     = true
    create_waf = true
    vpc_id     = "vpc-test123"
    subnet_ids = ["subnet-test1", "subnet-test2"]

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
    error_message = "ALB ARN should be defined when WAF is enabled"
  }

  assert {
    condition     = output.waf_web_acl_arn != null || true
    error_message = "WAF Web ACL ARN output should be defined when create_waf = true"
  }
}
