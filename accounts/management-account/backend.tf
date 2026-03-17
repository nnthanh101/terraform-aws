# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# ADR-006: S3 native state locking (use_lockfile = true, NO DynamoDB)
#
# PORTABLE: bucket + region injected at init time via -backend-config:
#   terraform init -backend-config="bucket=${BUCKET}" -backend-config="region=${REGION}"
# Convention: bucket = ${ACCOUNT_ID}-tfstate-${REGION}
#
# Migration from projects/sso/: state key changed from projects/sso/ to accounts/management-account/
# See README.md for state migration instructions.

terraform {
  backend "s3" {
    key          = "accounts/management-account/terraform.tfstate"
    use_lockfile = true
  }
}
