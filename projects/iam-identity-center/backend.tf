# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# ADR-006: S3 native state locking (no DynamoDB)
#
# LOCAL BACKEND: Used for dev/sandbox iteration (no S3 bucket required).
# Switch to the S3 backend block below when a state bucket is provisioned.
#
# ADR-006: S3 native locking (use_lockfile = true, NO DynamoDB)
# Bucket: 728863344838-tfstate-ap-southeast-2 (created 2026-03-01)
terraform {
  backend "s3" {
    region       = "ap-southeast-2"
    bucket       = "728863344838-tfstate-ap-southeast-2"
    key          = "projects/iam-identity-center/terraform.tfstate"
    use_lockfile = true
  }
}
