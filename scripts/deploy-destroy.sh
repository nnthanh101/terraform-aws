#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# deploy-destroy.sh — Run terraform destroy with auto-approve.
#
# Lists current state before destroying for visibility. For the
# iam-identity-center module, runs a post-destroy orphan check to detect
# any SSO resources (permission sets, groups) not cleaned up by Terraform.
#
# Usage:
#   MODULE=iam-identity-center bash scripts/deploy-destroy.sh
#
# Prereq:
#   deploy-init.sh must have been run first (produces .terraform/ directory)
#
# HITL requirements:
#   This script uses -auto-approve. Caller is responsible for ensuring
#   the correct module and account are targeted before running.
#
# Output:
#   Destroy log: tmp/terraform-aws/deployment-logs/destroy-${MODULE}-${DATE}.log

set -euo pipefail

MODULE="${MODULE:-iam-identity-center}"
PROJECT_DIR="projects/${MODULE}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Resolve script directory so sub-scripts can be called portably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== deploy:destroy [MODULE=${MODULE}] ==="

# Guard: init must have been run
if [ ! -d "${PROJECT_DIR}/.terraform" ]; then
  echo "ERROR: ${PROJECT_DIR}/.terraform not found." >&2
  echo "HINT: Run 'task deploy:init MODULE=${MODULE}' first." >&2
  exit 1
fi

mkdir -p "${EVIDENCE_DIR}/deployment-logs"

# --- Show current state before destroying ---
echo ""
echo "--- Current state ---"
terraform -chdir="$PROJECT_DIR" state list 2>/dev/null || echo "(no state)"
echo ""

# --- Run destroy ---
echo "--- Running terraform destroy ---"
terraform -chdir="$PROJECT_DIR" destroy \
  -input=false \
  -no-color \
  -auto-approve \
  2>&1 | tee "${EVIDENCE_DIR}/deployment-logs/destroy-${MODULE}-${DATE}.log"

DESTROY_EXIT="${PIPESTATUS[0]}"

# --- Post-destroy orphan check (iam-identity-center only) ---
if [ "$MODULE" = "iam-identity-center" ] && [ "$DESTROY_EXIT" -eq 0 ]; then
  echo ""
  echo "--- Post-destroy orphan check (SSO) ---"
  SSO_REGION=$(bash "${SCRIPT_DIR}/resolve-sso-region.sh" 2>/dev/null || echo "")

  if [ -n "$SSO_REGION" ]; then
    INSTANCE_ARN=$(aws sso-admin list-instances \
      --region "$SSO_REGION" \
      --query 'Instances[0].InstanceArn' \
      --output text 2>/dev/null || echo "None")
    IDENTITY_STORE_ID=$(aws sso-admin list-instances \
      --region "$SSO_REGION" \
      --query 'Instances[0].IdentityStoreId' \
      --output text 2>/dev/null || echo "None")

    if [ "$INSTANCE_ARN" != "None" ] && [ -n "$INSTANCE_ARN" ]; then
      PS_COUNT=$(aws sso-admin list-permission-sets \
        --instance-arn "$INSTANCE_ARN" \
        --region "$SSO_REGION" \
        --query 'PermissionSets | length(@)' \
        --output text 2>/dev/null || echo "?")
      GROUP_COUNT=$(aws identitystore list-groups \
        --identity-store-id "$IDENTITY_STORE_ID" \
        --region "$SSO_REGION" \
        --query 'Groups | length(@)' \
        --output text 2>/dev/null || echo "?")

      echo "SSO Instance:            ${INSTANCE_ARN}"
      echo "SSO Region:              ${SSO_REGION}"
      echo "Permission Sets remaining: ${PS_COUNT}"
      echo "Groups remaining:          ${GROUP_COUNT}"

      if [ "$PS_COUNT" = "0" ] && [ "$GROUP_COUNT" = "0" ]; then
        echo "CLEAN: No orphan SSO resources detected"
      else
        echo "WARN: Orphan SSO resources detected — manual cleanup may be needed in AWS Console"
      fi
    else
      echo "INFO: No SSO instance found — nothing to check"
    fi
  else
    echo "INFO: Could not resolve SSO region — skipping orphan check"
  fi
fi

if [ "$DESTROY_EXIT" -ne 0 ]; then
  echo ""
  echo "FAILED: deploy:destroy [MODULE=${MODULE}]" >&2
  echo "Log: ${EVIDENCE_DIR}/deployment-logs/destroy-${MODULE}-${DATE}.log" >&2
  exit 1
fi

echo ""
echo "Destroy log: ${EVIDENCE_DIR}/deployment-logs/destroy-${MODULE}-${DATE}.log"
echo ""
echo "PASSED: deploy:destroy [MODULE=${MODULE}]"
