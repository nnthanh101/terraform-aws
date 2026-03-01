#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# deploy-apply.sh — Run terraform apply using the saved plan file.
#
# Applies the plan produced by deploy-plan.sh. The plan file (tfplan) is
# consumed and deleted on successful apply to prevent stale re-apply.
# Terraform outputs are captured to JSON for evidence.
#
# Usage:
#   MODULE=iam-identity-center bash scripts/deploy-apply.sh
#
# Prereq:
#   deploy-plan.sh must have been run first (produces projects/${MODULE}/tfplan)
#
# Output:
#   Apply log:    tmp/terraform-aws/deployment-logs/apply-${MODULE}-${DATE}.log
#   Outputs JSON: tmp/terraform-aws/deployment-logs/outputs-${MODULE}-${DATE}.json

set -euo pipefail

MODULE="${MODULE:-iam-identity-center}"
PROJECT_DIR="projects/${MODULE}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

PLAN_FILE="${PROJECT_DIR}/tfplan"

echo "=== deploy:apply [MODULE=${MODULE}] ==="

# Guard: plan must have been run
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: ${PLAN_FILE} not found." >&2
  echo "HINT: Run 'task deploy:plan MODULE=${MODULE}' first." >&2
  exit 1
fi

mkdir -p "${EVIDENCE_DIR}/deployment-logs"

echo ""
echo "--- Running terraform apply ---"
terraform -chdir="$PROJECT_DIR" apply \
  -input=false \
  -no-color \
  tfplan \
  2>&1 | tee "${EVIDENCE_DIR}/deployment-logs/apply-${MODULE}-${DATE}.log"

APPLY_EXIT="${PIPESTATUS[0]}"

# Capture outputs on success
if [ "$APPLY_EXIT" -eq 0 ]; then
  echo ""
  echo "--- Terraform Outputs ---"
  terraform -chdir="$PROJECT_DIR" output -json \
    > "${EVIDENCE_DIR}/deployment-logs/outputs-${MODULE}-${DATE}.json" 2>/dev/null || true
  terraform -chdir="$PROJECT_DIR" output 2>/dev/null || true

  # Remove plan file after successful apply (prevents stale re-apply)
  rm -f "$PLAN_FILE"
  echo ""
  echo "Cleaned up: ${PLAN_FILE}"
fi

if [ "$APPLY_EXIT" -ne 0 ]; then
  echo ""
  echo "FAILED: deploy:apply [MODULE=${MODULE}]" >&2
  echo "Log: ${EVIDENCE_DIR}/deployment-logs/apply-${MODULE}-${DATE}.log" >&2
  exit 1
fi

echo ""
echo "Apply log:    ${EVIDENCE_DIR}/deployment-logs/apply-${MODULE}-${DATE}.log"
echo "Outputs JSON: ${EVIDENCE_DIR}/deployment-logs/outputs-${MODULE}-${DATE}.json"
echo ""
echo "PASSED: deploy:apply [MODULE=${MODULE}]"
