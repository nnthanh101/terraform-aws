# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: create=false produces null outputs (no resources planned)

mock_provider "aws" {}

run "alb_disabled_plan" {
  command = plan

  variables {
    create = false
    name   = "test-alb-disabled"
    tags = {
      Environment = "test"
      Project     = "alb"
    }
  }

  # Assert: ARN is null when create=false (aws_lb.this count=0, try(..., null) returns null)
  assert {
    condition     = output.arn == null
    error_message = "ALB ARN must be null when create=false"
  }

  # Assert: Security group is null when create=false (aws_security_group.this count=0)
  assert {
    condition     = output.security_group_id == null
    error_message = "Security group ID must be null when create=false"
  }

  # Assert: DNS name is null when create=false
  assert {
    condition     = output.dns_name == null
    error_message = "ALB DNS name must be null when create=false"
  }

  # Assert: Zone ID is null when create=false
  assert {
    condition     = output.zone_id == null
    error_message = "ALB zone_id must be null when create=false"
  }
}
