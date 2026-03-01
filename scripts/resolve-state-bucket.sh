#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# resolve-state-bucket.sh — Resolves or creates the S3 tfstate bucket.
#
# Convention: ${ACCOUNT_ID}-tfstate-${REGION}  (ADR-006)
# ADR-006: S3 native state locking (use_lockfile=true, NO DynamoDB)
#
# Usage:
#   ACCOUNT_ID=123456789012 REGION=ap-southeast-2 bash scripts/resolve-state-bucket.sh
#
# Output:
#   All status messages go to stderr.
#   Last line on stdout = machine-readable bucket name.
#
# HITL requirements:
#   1. Root account access (for first-time bucket creation)
#   2. Valid AWS credentials in environment

set -euo pipefail

ACCOUNT_ID="${ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")}"
REGION="${REGION:-ap-southeast-2}"

if [ -z "$ACCOUNT_ID" ]; then
  echo "ERROR: ACCOUNT_ID required (set env var or have valid AWS credentials)" >&2
  exit 1
fi

BUCKET="${ACCOUNT_ID}-tfstate-${REGION}"

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "EXISTS: s3://${BUCKET}" >&2
else
  echo "CREATING: s3://${BUCKET} in ${REGION}" >&2

  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" >&2

  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled >&2

  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >&2

  echo "CREATED: s3://${BUCKET}" >&2
fi

# Last line = machine-readable bucket name (consumed by deploy-init.sh)
echo "$BUCKET"
