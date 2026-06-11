# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: create_vpc=false kill-switch — no resources should be planned

mock_provider "aws" {}

run "vpc_disabled_plan" {
  command = plan

  variables {
    create_vpc = false
    name       = "disabled-vpc"
    cidr       = "10.0.0.0/16"

    azs             = ["ap-southeast-2a", "ap-southeast-2b"]
    public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  }

  assert {
    condition     = output.vpc_id == null
    error_message = "vpc_id should be null when create_vpc = false"
  }
}
