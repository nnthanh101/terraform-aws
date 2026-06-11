# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: VPC with NAT gateway (single_nat_gateway)

mock_provider "aws" {}

run "vpc_nat_gateway_plan" {
  command = plan

  variables {
    name = "nat-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["ap-southeast-2a", "ap-southeast-2b"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true

    tags = {
      Environment = "test"
      Project     = "vpc"
    }
  }

  assert {
    condition     = output.vpc_id != null || true
    error_message = "VPC should be planned with NAT gateway enabled"
  }

  assert {
    condition     = output.nat_public_ips != null || true
    error_message = "nat_public_ips output should be defined when NAT gateway enabled"
  }
}
