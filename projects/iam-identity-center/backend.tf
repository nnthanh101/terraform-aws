# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# ADR-006: S3 native state locking (use_lockfile = true, NO DynamoDB)
#
# PORTABLE: bucket + region injected at init time via -backend-config:
#   terraform init -backend-config="bucket=${BUCKET}" -backend-config="region=${REGION}"
# Or via: task deploy:init MODULE=iam-identity-center
# Convention: bucket = ${ACCOUNT_ID}-tfstate-${REGION}
terraform {
  backend "s3" {
    key          = "projects/iam-identity-center/terraform.tfstate"
    use_lockfile = true
  }
}
