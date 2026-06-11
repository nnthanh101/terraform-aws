# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: FARGATE + FARGATE_SPOT capacity providers (ADR-010)

mock_provider "aws" {}

run "fargate_and_spot_capacity" {
  command = plan

  variables {
    cluster_name               = "test-fargate-spot"
    cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy = {
      fargate = {
        base   = 1
        weight = 1
      }
      fargate_spot = {
        name   = "FARGATE_SPOT"
        weight = 4
      }
    }
    tags = {
      Environment = "test"
      Project     = "ecs"
    }
  }

  # Assert: cluster name matches
  assert {
    condition     = module.cluster.name == "test-fargate-spot"
    error_message = "Cluster name must be 'test-fargate-spot'"
  }
}
