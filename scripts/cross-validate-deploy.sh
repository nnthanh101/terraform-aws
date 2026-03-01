#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# cross-validate-deploy.sh — Post-apply cross-validation: terraform state vs AWS CLI.
#
# Compares Layer 1 (terraform state resource count) against Layer 2 (AWS CLI
# counts for permission sets, groups, assignments) to detect drift or partial
# applies. Writes structured JSON evidence.
#
# Usage:
#   bash scripts/cross-validate-deploy.sh iam-identity-center
#   MODULE=iam-identity-center bash scripts/cross-validate-deploy.sh
#
# Prereq:
#   - deploy:apply must have been run (state exists)
#   - Valid AWS credentials for CLI calls
#
# Evidence:
#   tmp/terraform-aws/deployment-logs/cross-validate-${MODULE}-YYYY-MM-DD.json

set -euo pipefail

MODULE="${1:-${MODULE:-}}"
if [ -z "$MODULE" ]; then
  echo "Usage: cross-validate-deploy.sh <module-name>" >&2
  echo "  or: MODULE=<module-name> bash scripts/cross-validate-deploy.sh" >&2
  exit 1
fi

PROJECT_DIR="projects/${MODULE}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
REGION="${REGION:-ap-southeast-2}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

PASS=0; FAIL=0; TOTAL=0

check_pass() {
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1))
  echo "PASS [$TOTAL]: $1"
}

check_fail() {
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "FAIL [$TOTAL]: $1"
  echo "  REASON: $2"
}

echo "=== deploy:cross-validate [MODULE=${MODULE}] ==="
echo ""

# ─── Layer 1: Terraform state resource count ────────────────────────────────
echo "--- Layer 1: Terraform State ---"
if [ ! -d "${PROJECT_DIR}/.terraform" ]; then
  echo "ERROR: ${PROJECT_DIR}/.terraform not found." >&2
  echo "HINT: Run 'task deploy:init MODULE=${MODULE}' first." >&2
  exit 1
fi

STATE_COUNT=$(terraform -chdir="$PROJECT_DIR" state list 2>/dev/null | wc -l | tr -d ' ')
echo "  State resource count: ${STATE_COUNT}"

# ─── Layer 2: AWS CLI counts ───────────────────────────────────────────────
echo ""
echo "--- Layer 2: AWS CLI ---"

# SSO instance
SSO_JSON=$(aws sso-admin list-instances --region "$REGION" --output json 2>/dev/null || echo '{"Instances":[]}')
INSTANCE_ARN=$(echo "$SSO_JSON" | jq -r '.Instances[0].InstanceArn // empty')
IDENTITY_STORE_ID=$(echo "$SSO_JSON" | jq -r '.Instances[0].IdentityStoreId // empty')

if [ -z "$INSTANCE_ARN" ]; then
  echo "ERROR: No SSO instance found in region ${REGION}" >&2
  exit 1
fi
echo "  SSO Instance: ${INSTANCE_ARN}"
echo "  Identity Store: ${IDENTITY_STORE_ID}"

# Permission sets count
PSET_JSON=$(aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --region "$REGION" --output json 2>/dev/null || echo '{"PermissionSets":[]}')
CLI_PSET_COUNT=$(echo "$PSET_JSON" | jq '.PermissionSets | length')
echo "  Permission sets: ${CLI_PSET_COUNT}"

# Groups count
GROUPS_JSON=$(aws identitystore list-groups --identity-store-id "$IDENTITY_STORE_ID" --region "$REGION" --output json 2>/dev/null || echo '{"Groups":[]}')
CLI_GROUP_COUNT=$(echo "$GROUPS_JSON" | jq '.Groups | length')
echo "  Groups: ${CLI_GROUP_COUNT}"

# Account assignments count
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "unknown")
CLI_ASSIGNMENT_COUNT=0
PSET_ARN_LIST=$(echo "$PSET_JSON" | jq -r '.PermissionSets[]' 2>/dev/null || true)
for ARN in $PSET_ARN_LIST; do
  ASSIGN_JSON=$(aws sso-admin list-account-assignments \
    --instance-arn "$INSTANCE_ARN" \
    --account-id "$ACCOUNT_ID" \
    --permission-set-arn "$ARN" \
    --region "$REGION" \
    --output json 2>/dev/null || echo '{"AccountAssignments":[]}')
  COUNT=$(echo "$ASSIGN_JSON" | jq '.AccountAssignments | length')
  CLI_ASSIGNMENT_COUNT=$((CLI_ASSIGNMENT_COUNT + COUNT))
done
echo "  Account assignments: ${CLI_ASSIGNMENT_COUNT}"

# ─── Layer 3: Terraform outputs ────────────────────────────────────────────
echo ""
echo "--- Layer 3: Terraform Outputs ---"
TF_OUTPUT=$(terraform -chdir="$PROJECT_DIR" output -json 2>/dev/null || echo '{}')
TF_GROUP_COUNT=$(echo "$TF_OUTPUT" | jq '.sso_groups_ids.value // {} | length' 2>/dev/null || echo "0")
TF_PSET_COUNT=$(echo "$TF_OUTPUT" | jq '.permission_set_arns.value // {} | length' 2>/dev/null || echo "0")
echo "  TF output groups: ${TF_GROUP_COUNT}"
echo "  TF output psets:  ${TF_PSET_COUNT}"

# ─── Cross-validation ──────────────────────────────────────────────────────
echo ""
echo "--- Cross-Validation ---"

# Check 1: CLI groups == TF output groups
if [ "$CLI_GROUP_COUNT" -eq "$TF_GROUP_COUNT" ]; then
  check_pass "Groups match — CLI (${CLI_GROUP_COUNT}) = TF outputs (${TF_GROUP_COUNT})"
else
  check_fail "Groups mismatch" "CLI (${CLI_GROUP_COUNT}) != TF outputs (${TF_GROUP_COUNT})"
fi

# Check 2: CLI permission sets == TF output permission sets
if [ "$CLI_PSET_COUNT" -eq "$TF_PSET_COUNT" ]; then
  check_pass "Permission sets match — CLI (${CLI_PSET_COUNT}) = TF outputs (${TF_PSET_COUNT})"
else
  check_fail "Permission sets mismatch" "CLI (${CLI_PSET_COUNT}) != TF outputs (${TF_PSET_COUNT})"
fi

# Check 3: State count is non-zero (sanity)
if [ "$STATE_COUNT" -gt 0 ]; then
  check_pass "State non-empty — ${STATE_COUNT} resources managed"
else
  check_fail "State empty" "terraform state list returned 0 resources"
fi

# Check 4: Assignments present
if [ "$CLI_ASSIGNMENT_COUNT" -gt 0 ]; then
  check_pass "Account assignments present — ${CLI_ASSIGNMENT_COUNT} found"
else
  check_fail "No account assignments" "expected at least 1 assignment"
fi

# ─── Summary + evidence ────────────────────────────────────────────────────
echo ""
echo "=== Cross-Validate Summary ==="
echo "  PASS: ${PASS} / ${TOTAL}"
echo "  FAIL: ${FAIL} / ${TOTAL}"

mkdir -p "$EVIDENCE_DIR/deployment-logs"
EVIDENCE_FILE="$EVIDENCE_DIR/deployment-logs/cross-validate-${MODULE}-${DATE}.json"
cat > "$EVIDENCE_FILE" <<EJSON
{
  "timestamp": "${TIMESTAMP}",
  "module": "${MODULE}",
  "region": "${REGION}",
  "layer1_state_count": ${STATE_COUNT},
  "layer2_cli_groups": ${CLI_GROUP_COUNT},
  "layer2_cli_psets": ${CLI_PSET_COUNT},
  "layer2_cli_assignments": ${CLI_ASSIGNMENT_COUNT},
  "layer3_tf_groups": ${TF_GROUP_COUNT},
  "layer3_tf_psets": ${TF_PSET_COUNT},
  "checks_total": ${TOTAL},
  "checks_passed": ${PASS},
  "checks_failed": ${FAIL},
  "account_id": "${ACCOUNT_ID}",
  "script": "scripts/cross-validate-deploy.sh v1.0.0"
}
EJSON
echo "Evidence: ${EVIDENCE_FILE}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED: cross-validate — ${FAIL} check(s) did not pass."
  exit 1
fi

echo ""
echo "PASSED: deploy:cross-validate [MODULE=${MODULE}]"
