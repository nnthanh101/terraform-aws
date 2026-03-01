# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# ADR-006: S3 native state locking (no DynamoDB)

terraform {
  backend "s3" {
    region       = "ap-southeast-2"
    bucket       = "TODO-tfstate-bucket"   # HITL: replace with your state bucket
    key          = "projects/iam-identity-center/terraform.tfstate"
    use_lockfile = true
  }
}
