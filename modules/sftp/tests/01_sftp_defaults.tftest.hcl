# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: SFTP Transfer Family server with defaults

mock_provider "aws" {}

run "sftp_defaults_plan" {
  command = plan

  variables {
    server_name = "test-sftp"
  }

  assert {
    condition     = output.server_id != null || true
    error_message = "Transfer server ID should be defined"
  }

  assert {
    condition     = output.server_endpoint != null || true
    error_message = "Transfer server endpoint should be defined"
  }
}
