#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# verify-deployment.sh — Cross-validate deployed AWS resources against Terraform outputs
#
# Usage:
#   MODULE=iam-identity-center bash scripts/verify-deployment.sh
#
# Checks:
#   1. SSO instance reachable (ARN + identity store ID)
#   2. Groups exist with expected names
#   3. Permission sets exist with expected names + session durations
#   4. Account assignments count matches expected
#   5. S3 state file exists and size > 0
#   6. terraform output -json returns non-empty keys
#   7. CLI group count vs Terraform output group count (drift detection)
#
# Evidence: tmp/terraform-aws/deployment-logs/verify-${MODULE}-YYYY-MM-DD.json
set -euo pipefail

# ─── inputs ───────────────────────────────────────────────────────────────────
MODULE="${MODULE:-iam-identity-center}"
PROJECT_DIR="${PROJECT_DIR:-projects/${MODULE}}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
REGION="${REGION:-ap-southeast-2}"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

source "$(dirname "${BASH_SOURCE[0]}")/lib/verify-helpers.sh"

# ─── expected state (4-tier) ──────────────────────────────────────────────────
EXPECTED_GROUPS="AuditTeam PlatformTeam PowerUsers SecurityTeam"
EXPECTED_PSETS="Admin PowerUser ReadOnly SecurityAudit"
EXPECTED_DURATIONS="Admin=PT1H PowerUser=PT4H ReadOnly=PT8H SecurityAudit=PT8H"
EXPECTED_ASSIGNMENT_COUNT=4

echo "=== verify-deployment [MODULE=${MODULE}] ==="
echo ""

# ─── check 1: SSO instance reachable ─────────────────────────────────────────
SSO_JSON=$(aws sso-admin list-instances --region "$REGION" --output json 2>/dev/null || echo '{"Instances":[]}')
INSTANCE_ARN=$(echo "$SSO_JSON" | jq -r '.Instances[0].InstanceArn // empty')
IDENTITY_STORE_ID=$(echo "$SSO_JSON" | jq -r '.Instances[0].IdentityStoreId // empty')

if [ -n "$INSTANCE_ARN" ]; then
  check_pass "SSO instance reachable — ARN: ${INSTANCE_ARN}, IdentityStore: ${IDENTITY_STORE_ID}"
else
  check_fail "SSO instance reachable" "aws sso-admin list-instances returned empty"
fi

# ─── check 2: groups exist ───────────────────────────────────────────────────
if [ -n "$IDENTITY_STORE_ID" ]; then
  GROUPS_JSON=$(aws identitystore list-groups --identity-store-id "$IDENTITY_STORE_ID" --region "$REGION" --output json 2>/dev/null || echo '{"Groups":[]}')
  ACTUAL_GROUPS=$(echo "$GROUPS_JSON" | jq -r '.Groups[].DisplayName' | sort | tr '\n' ' ' | sed 's/ $//')
  ACTUAL_GROUP_COUNT=$(echo "$GROUPS_JSON" | jq '.Groups | length')

  MISSING_GROUPS=""
  for G in $EXPECTED_GROUPS; do
    if ! echo "$ACTUAL_GROUPS" | grep -qw "$G"; then
      MISSING_GROUPS="${MISSING_GROUPS} ${G}"
    fi
  done

  if [ -z "$MISSING_GROUPS" ]; then
    check_pass "All expected groups exist — found: ${ACTUAL_GROUPS} (${ACTUAL_GROUP_COUNT} total)"
  else
    check_fail "Expected groups" "missing:${MISSING_GROUPS} — found: ${ACTUAL_GROUPS}"
  fi
else
  check_fail "Groups check" "skipped — no identity store ID"
  ACTUAL_GROUP_COUNT=0
  ACTUAL_GROUPS=""
fi

# ─── check 3: permission sets exist with correct session durations ───────────
if [ -n "$INSTANCE_ARN" ]; then
  PSET_ARNS=$(aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --region "$REGION" --output json 2>/dev/null || echo '{"PermissionSets":[]}')
  PSET_ARN_LIST=$(echo "$PSET_ARNS" | jq -r '.PermissionSets[]' 2>/dev/null || true)
  ACTUAL_PSET_COUNT=$(echo "$PSET_ARNS" | jq '.PermissionSets | length')

  PSET_DETAILS=""
  PSET_NAMES=""
  DURATION_MISMATCHES=""

  for ARN in $PSET_ARN_LIST; do
    DESC=$(aws sso-admin describe-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$ARN" --region "$REGION" --output json 2>/dev/null || echo '{}')
    NAME=$(echo "$DESC" | jq -r '.PermissionSet.Name // "unknown"')
    DURATION=$(echo "$DESC" | jq -r '.PermissionSet.SessionDuration // "unknown"')
    PSET_NAMES="${PSET_NAMES} ${NAME}"
    PSET_DETAILS="${PSET_DETAILS}${NAME}(${DURATION}) "

    # Check expected duration
    for PAIR in $EXPECTED_DURATIONS; do
      EXP_NAME="${PAIR%%=*}"
      EXP_DUR="${PAIR#*=}"
      if [ "$NAME" = "$EXP_NAME" ] && [ "$DURATION" != "$EXP_DUR" ]; then
        DURATION_MISMATCHES="${DURATION_MISMATCHES} ${NAME}: expected=${EXP_DUR}, actual=${DURATION}"
      fi
    done
  done

  MISSING_PSETS=""
  for PS in $EXPECTED_PSETS; do
    if ! echo "$PSET_NAMES" | grep -qw "$PS"; then
      MISSING_PSETS="${MISSING_PSETS} ${PS}"
    fi
  done

  if [ -z "$MISSING_PSETS" ]; then
    check_pass "All expected permission sets exist — ${PSET_DETAILS}"
  else
    check_fail "Expected permission sets" "missing:${MISSING_PSETS} — found:${PSET_NAMES}"
  fi

  if [ -z "$DURATION_MISMATCHES" ]; then
    check_pass "Permission set session durations match expected"
  else
    check_fail "Session duration mismatch" "$DURATION_MISMATCHES"
  fi
else
  check_fail "Permission sets check" "skipped — no instance ARN"
  ACTUAL_PSET_COUNT=0
fi

# ─── check 4: account assignments count ──────────────────────────────────────
if [ -n "$INSTANCE_ARN" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "unknown")
  ASSIGNMENT_COUNT=0

  for ARN in $PSET_ARN_LIST; do
    ASSIGN_JSON=$(aws sso-admin list-account-assignments \
      --instance-arn "$INSTANCE_ARN" \
      --account-id "$ACCOUNT_ID" \
      --permission-set-arn "$ARN" \
      --region "$REGION" \
      --output json 2>/dev/null || echo '{"AccountAssignments":[]}')
    COUNT=$(echo "$ASSIGN_JSON" | jq '.AccountAssignments | length')
    ASSIGNMENT_COUNT=$((ASSIGNMENT_COUNT + COUNT))
  done

  if [ "$ASSIGNMENT_COUNT" -ge "$EXPECTED_ASSIGNMENT_COUNT" ]; then
    check_pass "Account assignments: ${ASSIGNMENT_COUNT} found (expected >= ${EXPECTED_ASSIGNMENT_COUNT})"
  else
    check_fail "Account assignments" "found ${ASSIGNMENT_COUNT}, expected >= ${EXPECTED_ASSIGNMENT_COUNT}"
  fi
else
  check_fail "Account assignments" "skipped — no instance ARN"
fi

# ─── check 5: S3 state file ─────────────────────────────────────────────────
STATE_BUCKET="${ACCOUNT_ID:-unknown}-tfstate-${REGION}"
STATE_KEY="projects/${MODULE}/terraform.tfstate"

STATE_SIZE=$(aws s3api head-object --bucket "$STATE_BUCKET" --key "$STATE_KEY" --query 'ContentLength' --output text 2>/dev/null || echo "0")
if [ "$STATE_SIZE" -gt 0 ] 2>/dev/null; then
  check_pass "S3 state file exists — s3://${STATE_BUCKET}/${STATE_KEY} (${STATE_SIZE} bytes)"
else
  check_warn "S3 state file" "s3://${STATE_BUCKET}/${STATE_KEY} not found or empty — may be using local backend"
fi

# ─── check 6: terraform output -json ────────────────────────────────────────
if [ -d "$PROJECT_DIR" ]; then
  TF_OUTPUT=$(terraform -chdir="$PROJECT_DIR" output -json 2>/dev/null || echo '{}')
  OUTPUT_KEYS=$(echo "$TF_OUTPUT" | jq -r 'keys[]' 2>/dev/null || true)

  if [ -n "$OUTPUT_KEYS" ]; then
    OUTPUT_COUNT=$(echo "$OUTPUT_KEYS" | wc -l | tr -d ' ')
    check_pass "terraform output returns ${OUTPUT_COUNT} keys: $(echo "$OUTPUT_KEYS" | tr '\n' ' ')"
    TF_GROUP_COUNT=$(echo "$TF_OUTPUT" | jq '.sso_groups_ids.value // {} | length' 2>/dev/null || echo "0")
  else
    check_warn "terraform output" "no outputs found — may need terraform init + apply first"
    TF_GROUP_COUNT=0
  fi
else
  check_warn "terraform output" "project dir not found: ${PROJECT_DIR}"
  TF_GROUP_COUNT=0
fi

# ─── check 7: drift detection (CLI group count vs TF output) ────────────────
if [ "$ACTUAL_GROUP_COUNT" -gt 0 ] && [ "$TF_GROUP_COUNT" -gt 0 ]; then
  if [ "$ACTUAL_GROUP_COUNT" -eq "$TF_GROUP_COUNT" ]; then
    check_pass "No drift detected — AWS groups (${ACTUAL_GROUP_COUNT}) = TF outputs (${TF_GROUP_COUNT})"
  else
    check_warn "Potential drift" "AWS groups: ${ACTUAL_GROUP_COUNT}, TF outputs: ${TF_GROUP_COUNT}"
  fi
elif [ "$TF_GROUP_COUNT" -eq 0 ]; then
  check_warn "Drift detection" "TF output group count unavailable — run apply first"
else
  check_warn "Drift detection" "insufficient data (AWS: ${ACTUAL_GROUP_COUNT}, TF: ${TF_GROUP_COUNT})"
fi

# ─── summary + evidence ──────────────────────────────────────────────────────
echo ""
echo "=== Verify-Deployment Summary ==="
echo "  PASS: ${PASS} / ${TOTAL}"
echo "  FAIL: ${FAIL} / ${TOTAL}"
echo "  WARN: ${WARN} / ${TOTAL}"

mkdir -p "$EVIDENCE_DIR/deployment-logs"
EVIDENCE_FILE="$EVIDENCE_DIR/deployment-logs/verify-${MODULE}-${DATE}.json"
cat > "$EVIDENCE_FILE" <<EJSON
{
  "timestamp": "${TIMESTAMP}",
  "module": "${MODULE}",
  "region": "${REGION}",
  "checks_total": ${TOTAL},
  "checks_passed": ${PASS},
  "checks_failed": ${FAIL},
  "checks_warned": ${WARN},
  "aws_groups": "${ACTUAL_GROUPS}",
  "aws_group_count": ${ACTUAL_GROUP_COUNT:-0},
  "aws_pset_count": ${ACTUAL_PSET_COUNT:-0},
  "aws_assignment_count": ${ASSIGNMENT_COUNT:-0},
  "tf_group_count": ${TF_GROUP_COUNT:-0},
  "state_bucket": "${STATE_BUCKET}",
  "state_size_bytes": ${STATE_SIZE:-0},
  "script": "scripts/verify-deployment.sh v1.0.0"
}
EJSON
echo "Evidence: ${EVIDENCE_FILE}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED: verify-deployment — ${FAIL} check(s) did not pass."
  exit 1
fi

echo ""
echo "PASSED: verify-deployment [MODULE=${MODULE}]"
