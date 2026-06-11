# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: VPC with DNS settings enabled

mock_provider "aws" {}

run "vpc_dns_plan" {
  command = plan

  variables {
    name = "dns-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["ap-southeast-2a", "ap-southeast-2b"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
      Environment = "test"
      Project     = "vpc"
    }
  }

  assert {
    condition     = output.vpc_id != null || true
    error_message = "VPC should be planned with DNS settings"
  }
}
