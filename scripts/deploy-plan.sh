#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# deploy-plan.sh — Run terraform plan and save the plan file for HITL review.
#
# The plan file (tfplan) is saved inside the project directory. It is consumed
# by deploy-apply.sh. The human-in-the-loop must review the plan output log
# before approving apply.
#
# Usage:
#   MODULE=iam-identity-center bash scripts/deploy-plan.sh
#
# Prereq:
#   deploy-init.sh must have been run first (produces .terraform/ directory)
#
# Output:
#   Plan binary:  projects/${MODULE}/tfplan
#   Plan log:     tmp/terraform-aws/deployment-logs/plan-${MODULE}-${DATE}.log

set -euo pipefail

MODULE="${MODULE:-iam-identity-center}"
PROJECT_DIR="projects/${MODULE}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "=== deploy:plan [MODULE=${MODULE}] ==="

# Guard: init must have been run
if [ ! -d "${PROJECT_DIR}/.terraform" ]; then
  echo "ERROR: ${PROJECT_DIR}/.terraform not found." >&2
  echo "HINT: Run 'task deploy:init MODULE=${MODULE}' first." >&2
  exit 1
fi

mkdir -p "${EVIDENCE_DIR}/deployment-logs"

echo ""
echo "--- Running terraform plan ---"
terraform -chdir="$PROJECT_DIR" plan \
  -input=false \
  -out=tfplan \
  2>&1 | tee "${EVIDENCE_DIR}/deployment-logs/plan-${MODULE}-${DATE}.log"

PLAN_EXIT="${PIPESTATUS[0]}"

if [ "$PLAN_EXIT" -ne 0 ]; then
  echo ""
  echo "FAILED: deploy:plan [MODULE=${MODULE}]" >&2
  exit 1
fi

echo ""
echo "Plan saved:  ${PROJECT_DIR}/tfplan"
echo "Plan log:    ${EVIDENCE_DIR}/deployment-logs/plan-${MODULE}-${DATE}.log"
echo ""
echo "HITL: Review the plan log above before running 'task deploy:apply'."
echo ""
echo "PASSED: deploy:plan [MODULE=${MODULE}]"
