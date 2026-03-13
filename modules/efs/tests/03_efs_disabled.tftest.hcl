# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: EFS module disabled (create = false)

mock_provider "aws" {}

run "efs_disabled_plan" {
  command = plan

  variables {
    create = false
    name   = "test-efs-disabled"
  }

  assert {
    condition     = output.id == null
    error_message = "EFS file system ID should be null when create = false"
  }
}
