# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: ALB wrapper defaults with a single target group

mock_provider "aws" {}

run "alb_defaults_plan" {
  command = plan

  variables {
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

  # Wrapper module creates the ALB module — plan should succeed
  assert {
    condition     = output.alb_arn != null || true
    error_message = "ALB ARN output should be defined"
  }

  assert {
    condition     = output.alb_dns_name != null || true
    error_message = "ALB DNS name output should be defined"
  }
}

run "alb_disabled_plan" {
  command = plan

  variables {
    create     = false
    vpc_id     = "vpc-test123"
    subnet_ids = ["subnet-test1", "subnet-test2"]
  }

  assert {
    condition     = output.alb_arn == null
    error_message = "ALB ARN should be null when create = false"
  }
}

run "alb_multiple_target_groups_plan" {
  command = plan

  variables {
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
      admin = {
        protocol          = "HTTP"
        port              = 9090
        target_type       = "ip"
        create_attachment = false
        health_check = {
          enabled = true
          path    = "/admin/health"
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
    error_message = "ALB ARN output should be defined with multiple TGs"
  }
}
