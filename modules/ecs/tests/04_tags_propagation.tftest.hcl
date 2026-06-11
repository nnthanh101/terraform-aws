# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Tags propagation to cluster

mock_provider "aws" {}

run "tags_on_cluster" {
  command = plan

  variables {
    cluster_name               = "test-tags"
    cluster_capacity_providers = ["FARGATE"]
    tags = {
      CostCenter         = "platform"
      Project            = "ecs"
      Environment        = "test"
      ServiceName        = "ecs"
      DataClassification = "internal"
    }
  }

  # Assert: cluster name set
  assert {
    condition     = module.cluster.name == "test-tags"
    error_message = "Cluster name must be 'test-tags'"
  }
}
