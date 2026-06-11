# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: create_bucket = false kill-switch produces no resources

mock_provider "aws" {}

run "bucket_disabled_plan" {
  command = plan

  variables {
    create_bucket = false
    bucket        = "test-bucket-disabled"
  }

  # Assert: bucket ID is empty string when create_bucket=false
  # outputs use try(..., "") so empty string is the expected disabled value
  assert {
    condition     = output.s3_bucket_id == ""
    error_message = "s3_bucket_id must be empty string when create_bucket=false"
  }

  # Assert: bucket ARN is empty string when create_bucket=false
  assert {
    condition     = output.s3_bucket_arn == ""
    error_message = "s3_bucket_arn must be empty string when create_bucket=false"
  }

  # Assert: bucket region is empty string when create_bucket=false
  assert {
    condition     = output.s3_bucket_region == ""
    error_message = "s3_bucket_region must be empty string when create_bucket=false"
  }

  # Assert: versioning status is null when create_bucket=false
  assert {
    condition     = output.aws_s3_bucket_versioning_status == null
    error_message = "versioning status must be null when create_bucket=false"
  }

  # Assert: directory bucket outputs are null when regular bucket disabled
  assert {
    condition     = output.s3_directory_bucket_name == null
    error_message = "s3_directory_bucket_name must be null when create_bucket=false"
  }
}
