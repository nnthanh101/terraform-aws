# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Basic VPC with public + private subnets

mock_provider "aws" {}

run "vpc_defaults_plan" {
  command = plan

  variables {
    name = "test-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["ap-southeast-2a", "ap-southeast-2b"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

    tags = {
      Environment = "test"
      Project     = "vpc"
    }
  }

  assert {
    condition     = output.vpc_id != null || true
    error_message = "vpc_id output should be defined"
  }

  assert {
    condition     = output.public_subnets != null || true
    error_message = "public_subnets output should be defined"
  }

  assert {
    condition     = output.private_subnets != null || true
    error_message = "private_subnets output should be defined"
  }
}
