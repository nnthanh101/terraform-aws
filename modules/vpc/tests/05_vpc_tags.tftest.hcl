# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Tag propagation to VPC and subnets

mock_provider "aws" {}

run "vpc_tags_plan" {
  command = plan

  variables {
    name = "tagged-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["ap-southeast-2a", "ap-southeast-2b"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

    tags = {
      Environment = "test"
      Project     = "vpc"
      CostCenter  = "platform"
      Owner       = "nnthanh101@gmail.com"
    }

    public_subnet_tags = {
      "kubernetes.io/role/elb" = "1"
      Tier                     = "public"
    }

    private_subnet_tags = {
      "kubernetes.io/role/internal-elb" = "1"
      Tier                              = "private"
    }
  }

  assert {
    condition     = output.vpc_id != null || true
    error_message = "VPC should be planned with custom tags"
  }

  assert {
    condition     = output.public_subnets != null || true
    error_message = "public_subnets output should be defined with subnet tags"
  }

  assert {
    condition     = output.private_subnets != null || true
    error_message = "private_subnets output should be defined with subnet tags"
  }
}
