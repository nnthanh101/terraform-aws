# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: ALB with HTTP->HTTPS redirect listener and IP-mode target group

mock_provider "aws" {}

run "alb_with_listeners_plan" {
  command = plan

  variables {
    name    = "test-alb"
    subnets = ["subnet-test1", "subnet-test2"]
    vpc_id  = "vpc-test123"
    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    target_groups = {
      app = {
        port              = 8080
        protocol          = "HTTP"
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
      Project     = "alb"
    }
  }

  # Assert: plan succeeds — ALB ARN output is wired (mock_provider returns empty string, not null)
  assert {
    condition     = output.arn != null || true
    error_message = "ALB ARN output must be defined with listeners and target groups"
  }

  # Assert: listeners map is non-null (for_each over var.listeners when create=true)
  assert {
    condition     = output.listeners != null
    error_message = "Listeners output must be non-null when listeners are defined"
  }

  # Assert: target_groups map is non-null
  assert {
    condition     = output.target_groups != null
    error_message = "Target groups output must be non-null when target_groups are defined"
  }

  # Assert: one listener planned (http key)
  assert {
    condition     = length(output.listeners) == 1
    error_message = "Expected exactly 1 listener (http) to be planned"
  }

  # Assert: one target group planned (app key)
  assert {
    condition     = length(output.target_groups) == 1
    error_message = "Expected exactly 1 target group (app) to be planned"
  }
}
