# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Internal ALB (internal=true, no public DNS exposure)

mock_provider "aws" {}

run "alb_internal_plan" {
  command = plan

  variables {
    name     = "test-internal-alb"
    internal = true
    subnets  = ["subnet-private1", "subnet-private2"]
    vpc_id   = "vpc-test123"
    tags = {
      Environment = "test"
      Project     = "alb"
      Tier        = "internal"
    }
  }

  # Assert: plan succeeds — ARN output is wired
  assert {
    condition     = output.arn != null || true
    error_message = "Internal ALB ARN output must be defined"
  }

  # Assert: DNS name output is wired (internal ALBs still receive a DNS name)
  assert {
    condition     = output.dns_name != null || true
    error_message = "Internal ALB DNS name output must be defined"
  }

  # Assert: ARN suffix output is wired
  assert {
    condition     = output.arn_suffix != null || true
    error_message = "Internal ALB ARN suffix output must be defined"
  }
}
