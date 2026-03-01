#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# sandbox-preflight.sh — Pre-flight checks before sandbox plan/apply/destroy
#
# Usage (CI):
#   MODULE=iam-identity-center ENVIRONMENT=sandbox STATE_BUCKET=<name> \
#     PROJECT_DIR=projects/iam-identity-center bash scripts/sandbox-preflight.sh
#
# Usage (local):
#   MODULE=iam-identity-center ENVIRONMENT=sandbox STATE_BUCKET="" \
#     PROJECT_DIR=projects/iam-identity-center bash scripts/sandbox-preflight.sh
#
# Exits non-zero with a clear error message if any check fails.
set -euo pipefail

# ─── inputs ───────────────────────────────────────────────────────────────────
MODULE="${MODULE:-}"
ENVIRONMENT="${ENVIRONMENT:-sandbox}"
STATE_BUCKET="${STATE_BUCKET:-}"
PROJECT_DIR="${PROJECT_DIR:-projects/${MODULE}}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

PASS=0; FAIL=0; TOTAL=0

# ─── helper: pass / fail ──────────────────────────────────────────────────────
check_pass() {
  local label="$1"
  TOTAL=$((TOTAL + 1))
  PASS=$((PASS + 1))
  echo "PASS [$TOTAL]: ${label}"
}

check_fail() {
  local label="$1"
  local reason="$2"
  TOTAL=$((TOTAL + 1))
  FAIL=$((FAIL + 1))
  echo "FAIL [$TOTAL]: ${label}"
  echo "  REASON: ${reason}"
}

echo "=== sandbox-preflight [MODULE=${MODULE}, ENV=${ENVIRONMENT}] ==="
echo ""

# ─── check 0: required inputs ─────────────────────────────────────────────────
if [ -z "$MODULE" ]; then
  echo "ERROR: MODULE is required (e.g. MODULE=iam-identity-center)" >&2
  exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: PROJECT_DIR not found: $PROJECT_DIR" >&2
  exit 1
fi

# ─── check 1: AWS authentication ─────────────────────────────────────────────
# Verify the AWS credentials are functional before attempting any Terraform ops.
if aws sts get-caller-identity --output text >/dev/null 2>&1; then
  IDENTITY=$(aws sts get-caller-identity --output text --query 'Arn' 2>/dev/null || echo "unknown")
  check_pass "AWS authentication — identity: ${IDENTITY}"
else
  check_fail "AWS authentication" "aws sts get-caller-identity failed — check OIDC role or static credentials"
fi

# ─── check 2: IAM Identity Center instance reachable ─────────────────────────
# Only run for modules that use SSO/Identity Center resources.
if [ "$MODULE" = "iam-identity-center" ]; then
  SSO_INSTANCES=$(aws sso-admin list-instances --query 'Instances[*].InstanceArn' --output text 2>/dev/null || true)
  if [ -n "$SSO_INSTANCES" ]; then
    check_pass "IAM Identity Center instance reachable — arn: $(echo "${SSO_INSTANCES}" | head -1)"
  else
    check_fail "IAM Identity Center instance reachable" \
      "aws sso-admin list-instances returned empty — Identity Center not enabled or no permission"
  fi
fi

# ─── check 3: Terraform state bucket exists (if STATE_BUCKET is set) ──────────
if [ -n "$STATE_BUCKET" ]; then
  if aws s3api head-bucket --bucket "$STATE_BUCKET" >/dev/null 2>&1; then
    check_pass "Terraform state bucket exists — s3://${STATE_BUCKET}"
  else
    check_fail "Terraform state bucket exists" \
      "s3://${STATE_BUCKET} not found or no s3:HeadBucket permission — create bucket first"
  fi
else
  echo "SKIP: STATE_BUCKET not set — using local backend (no S3 check)"
  TOTAL=$((TOTAL + 1))
fi

# ─── check 4: terraform fmt -check ────────────────────────────────────────────
if terraform fmt -check "$PROJECT_DIR" >/dev/null 2>&1; then
  check_pass "terraform fmt -check (${PROJECT_DIR})"
else
  check_fail "terraform fmt -check (${PROJECT_DIR})" \
    "unformatted .tf files detected — run: terraform fmt ${PROJECT_DIR}"
fi

# ─── check 5: terraform init + validate ───────────────────────────────────────
INIT_LOG=$(mktemp)
VALIDATE_LOG=$(mktemp)

if terraform -chdir="$PROJECT_DIR" init -backend=false -input=false >"$INIT_LOG" 2>&1; then
  check_pass "terraform init -backend=false (${PROJECT_DIR})"

  if terraform -chdir="$PROJECT_DIR" validate >"$VALIDATE_LOG" 2>&1; then
    check_pass "terraform validate (${PROJECT_DIR})"
  else
    check_fail "terraform validate (${PROJECT_DIR})" "$(cat "$VALIDATE_LOG")"
  fi
else
  check_fail "terraform init -backend=false (${PROJECT_DIR})" "$(cat "$INIT_LOG")"
  echo "SKIP: terraform validate (init failed)"
  TOTAL=$((TOTAL + 1))
fi

rm -f "$INIT_LOG" "$VALIDATE_LOG"

# ─── summary + evidence ───────────────────────────────────────────────────────
echo ""
echo "=== Pre-flight Summary ==="
echo "  PASS: ${PASS} / ${TOTAL}"
echo "  FAIL: ${FAIL} / ${TOTAL}"

mkdir -p "$EVIDENCE_DIR/deployment-logs"
EVIDENCE_FILE="$EVIDENCE_DIR/deployment-logs/preflight-${MODULE}-${DATE}.json"
cat > "$EVIDENCE_FILE" <<EJSON
{
  "timestamp": "${TIMESTAMP}",
  "module": "${MODULE}",
  "environment": "${ENVIRONMENT}",
  "project_dir": "${PROJECT_DIR}",
  "state_bucket": "${STATE_BUCKET:-local}",
  "checks_total": ${TOTAL},
  "checks_passed": ${PASS},
  "checks_failed": ${FAIL},
  "script": "scripts/sandbox-preflight.sh v1.0.0"
}
EJSON
echo "Evidence: ${EVIDENCE_FILE}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED: sandbox-preflight — ${FAIL} check(s) did not pass. Aborting deploy."
  exit 1
fi

echo ""
echo "PASSED: sandbox-preflight [MODULE=${MODULE}, ENV=${ENVIRONMENT}]"
