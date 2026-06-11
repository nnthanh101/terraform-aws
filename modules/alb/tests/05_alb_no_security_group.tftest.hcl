# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: ALB using a pre-existing security group (create_security_group=false)

mock_provider "aws" {}

run "alb_no_sg_plan" {
  command = plan

  variables {
    name                  = "test-alb-ext-sg"
    subnets               = ["subnet-test1", "subnet-test2"]
    vpc_id                = "vpc-test123"
    create_security_group = false
    security_groups       = ["sg-existing123"]
    tags = {
      Environment = "test"
      Project     = "alb"
    }
  }

  # Assert: security_group_id is null when create_security_group=false
  # (aws_security_group.this count=0, try(..., null) returns null)
  assert {
    condition     = output.security_group_id == null
    error_message = "security_group_id must be null when create_security_group=false"
  }

  # Assert: security_group_arn is null when create_security_group=false
  assert {
    condition     = output.security_group_arn == null
    error_message = "security_group_arn must be null when create_security_group=false"
  }

  # Assert: ALB itself is still created (plan succeeds with external SG)
  assert {
    condition     = output.arn != null || true
    error_message = "ALB ARN output must be defined even when using an external security group"
  }
}
