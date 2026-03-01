#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# deploy-init.sh — Initialize a project for deployment.
#
# Steps:
#   1. Resolve AWS account ID from current credentials
#   2. Resolve or create S3 tfstate bucket (ADR-006: use_lockfile=true, NO DynamoDB)
#   3. Detect SSO region (for iam-identity-center module)
#   4. Write .auto.tfvars.json with account-specific values (gitignored)
#   5. Run terraform init with partial backend config
#   6. Write evidence JSON to tmp/terraform-aws/deployment-logs/
#
# Usage:
#   MODULE=iam-identity-center bash scripts/deploy-init.sh
#   MODULE=iam-identity-center REGION=ap-southeast-2 bash scripts/deploy-init.sh
#
# HITL requirements:
#   1. Root account access (for first-time bucket creation)
#   2. SSO enabled in AWS Console (for iam-identity-center module)
#
# Portable: works for ANY AWS management account. Account ID is auto-detected.

set -euo pipefail

MODULE="${MODULE:-iam-identity-center}"
REGION="${REGION:-ap-southeast-2}"
PROJECT_DIR="projects/${MODULE}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Resolve script directory so sub-scripts can be called portably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== deploy:init [MODULE=${MODULE}] ==="

# Validate project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: Project directory not found: ${PROJECT_DIR}" >&2
  echo "HINT: Run from the terraform-aws root directory" >&2
  exit 1
fi

# --- Step 1: Resolve account ID ---
echo ""
echo "--- Step 1: Resolve account ID ---"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$ACCOUNT_ID" ]; then
  echo "ERROR: AWS credentials not configured." >&2
  echo "HINT: Run: aws sso login --profile <your-profile>" >&2
  exit 1
fi
echo "Account: ${ACCOUNT_ID}"

# --- Step 2: Resolve state bucket ---
echo ""
echo "--- Step 2: Resolve state bucket (ADR-006) ---"
BUCKET=$(ACCOUNT_ID="$ACCOUNT_ID" REGION="$REGION" bash "${SCRIPT_DIR}/resolve-state-bucket.sh")
echo "Bucket: ${BUCKET}"

# --- Step 3: Detect SSO region (iam-identity-center only) ---
SSO_REGION="$REGION"
if [ "$MODULE" = "iam-identity-center" ]; then
  echo ""
  echo "--- Step 3: Detect SSO region ---"
  SSO_REGION=$(bash "${SCRIPT_DIR}/resolve-sso-region.sh")
  echo "SSO Region: ${SSO_REGION}"
fi

# --- Step 4: Write .auto.tfvars.json (gitignored, account-specific) ---
echo ""
echo "--- Step 4: Write .auto.tfvars.json ---"
TFVARS_FILE="${PROJECT_DIR}/.auto.tfvars.json"
cat > "$TFVARS_FILE" <<EJSON
{
  "account_id": "${ACCOUNT_ID}",
  "sso_region": "${SSO_REGION}"
}
EJSON
echo "Written: ${TFVARS_FILE}"

# --- Step 5: terraform init with partial backend config ---
echo ""
echo "--- Step 5: terraform init (partial backend config) ---"
terraform -chdir="$PROJECT_DIR" init \
  -input=false \
  -backend-config="bucket=${BUCKET}" \
  -backend-config="region=${REGION}" \
  -reconfigure

# --- Step 6: Write evidence ---
mkdir -p "${EVIDENCE_DIR}/deployment-logs"
cat > "${EVIDENCE_DIR}/deployment-logs/init-${MODULE}-${DATE}.json" <<EJSON
{
  "timestamp": "${TIMESTAMP}",
  "module": "${MODULE}",
  "account_id": "${ACCOUNT_ID}",
  "region": "${REGION}",
  "sso_region": "${SSO_REGION}",
  "bucket": "${BUCKET}",
  "tfvars_file": "${TFVARS_FILE}",
  "script": "scripts/deploy-init.sh v1.0.0"
}
EJSON
echo ""
echo "Evidence: ${EVIDENCE_DIR}/deployment-logs/init-${MODULE}-${DATE}.json"

echo ""
echo "PASSED: deploy:init [MODULE=${MODULE}, ACCOUNT=${ACCOUNT_ID}, BUCKET=${BUCKET}]"
