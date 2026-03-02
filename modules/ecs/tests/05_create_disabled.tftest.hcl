# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: create = false produces no resources (kill-switch)
# Redesigned per CA BLOCK-001: version constraints tested by task govern:legal

mock_provider "aws" {}

run "create_false_no_resources" {
  command = plan

  variables {
    create       = false
    cluster_name = "test-disabled"
  }

  # Assert: no cluster created when create = false
  assert {
    condition     = module.cluster.arn == null
    error_message = "Expected no cluster ARN when create = false"
  }

  # Assert: no services created
  assert {
    condition     = length(module.service) == 0
    error_message = "Expected no services when create = false"
  }
}
