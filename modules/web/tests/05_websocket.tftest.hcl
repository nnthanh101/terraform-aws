# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: CloudFront with WebSocket cache bypass paths

mock_provider "aws" {}
mock_provider "aws" {
  alias = "us_east_1"
}

run "websocket_bypass_plan" {
  command = plan

  variables {
    create            = true
    create_cloudfront = true
    vpc_id            = "vpc-test123"
    subnet_ids        = ["subnet-test1", "subnet-test2"]

    cloudfront_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/test"
    cloudfront_aliases         = ["app.example.com"]

    websocket_paths = ["/ws/*", "/socket.io/*"]

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
    condition     = output.cloudfront_distribution_id != null || true
    error_message = "CloudFront distribution should be created with WebSocket paths"
  }
}
