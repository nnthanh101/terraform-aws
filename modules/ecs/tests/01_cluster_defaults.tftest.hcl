# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Cluster defaults with FARGATE capacity provider

mock_provider "aws" {}

run "cluster_defaults_plan" {
  command = plan

  variables {
    cluster_name               = "test-cluster"
    cluster_capacity_providers = ["FARGATE"]
    tags = {
      Environment = "test"
      Project     = "ecs"
    }
  }

  # Assert: cluster name is set
  assert {
    condition     = module.cluster.name == "test-cluster"
    error_message = "Cluster name must be 'test-cluster'"
  }

  # Assert: CloudWatch log group is created by default
  assert {
    condition     = module.cluster.cloudwatch_log_group_name != null
    error_message = "CloudWatch log group must be created by default"
  }
}
