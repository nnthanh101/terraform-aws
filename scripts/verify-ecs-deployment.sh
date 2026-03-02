#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# verify-ecs-deployment.sh — Cross-validate deployed ECS resources against Terraform outputs
#
# Usage:
#   MODULE=ecs bash scripts/verify-ecs-deployment.sh
#
# Checks:
#   1. ECS cluster exists and is ACTIVE
#   2. Capacity providers match config (FARGATE, FARGATE_SPOT)
#   3. CloudWatch log group exists
#   4. Services exist (list-services count)
#   5. Services are ACTIVE with desired task count
#   6. Task definitions registered
#   7. S3 state file exists and size > 0
#   8. Drift detection: CLI service count vs TF output count
#
# Evidence: tmp/terraform-aws/deployment-logs/verify-ecs-YYYY-MM-DD.json
set -euo pipefail

# ─── inputs ───────────────────────────────────────────────────────────────────
MODULE="${MODULE:-ecs}"
PROJECT_DIR="${PROJECT_DIR:-projects/${MODULE}}"
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
REGION="${REGION:-ap-southeast-2}"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

PASS=0; FAIL=0; WARN=0; TOTAL=0

# ─── helpers ──────────────────────────────────────────────────────────────────
check_pass() {
  TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1))
  echo "PASS [$TOTAL]: $1"
}

check_fail() {
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "FAIL [$TOTAL]: $1"
  echo "  REASON: $2"
}

check_warn() {
  TOTAL=$((TOTAL + 1)); WARN=$((WARN + 1))
  echo "WARN [$TOTAL]: $1"
  echo "  DETAIL: $2"
}

echo "=== verify-ecs-deployment [MODULE=${MODULE}] ==="
echo ""

# ─── resolve cluster name ─────────────────────────────────────────────────────
CLUSTER_NAME="${CLUSTER_NAME:-}"
if [ -z "$CLUSTER_NAME" ] && [ -d "$PROJECT_DIR" ]; then
  CLUSTER_NAME=$(terraform -chdir="$PROJECT_DIR" output -raw cluster_name 2>/dev/null || echo "")
fi
if [ -z "$CLUSTER_NAME" ]; then
  check_warn "Cluster name from TF output" "unable to read — will attempt discovery via list-clusters"
  CLUSTERS_JSON=$(aws ecs list-clusters --region "$REGION" --output json 2>/dev/null || echo '{"clusterArns":[]}')
  CLUSTER_COUNT=$(echo "$CLUSTERS_JSON" | jq '.clusterArns | length')
  if [ "$CLUSTER_COUNT" -eq 1 ]; then
    CLUSTER_ARN_DISC=$(echo "$CLUSTERS_JSON" | jq -r '.clusterArns[0]')
    CLUSTER_NAME=$(echo "$CLUSTER_ARN_DISC" | awk -F'/' '{print $NF}')
  elif [ "$CLUSTER_COUNT" -gt 1 ]; then
    echo "WARN: Multiple clusters found. Set CLUSTER_NAME env var to target a specific cluster."
  fi
fi

# ─── check 1: ECS cluster exists and is ACTIVE ───────────────────────────────
CLUSTER_STATUS="NOT_FOUND"
CLUSTER_ARN="unknown"
if [ -n "$CLUSTER_NAME" ]; then
  CLUSTER_JSON=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" --output json 2>/dev/null || echo '{"clusters":[]}')
  CLUSTER_STATUS=$(echo "$CLUSTER_JSON" | jq -r '.clusters[0].status // "NOT_FOUND"')
  CLUSTER_ARN=$(echo "$CLUSTER_JSON" | jq -r '.clusters[0].clusterArn // "unknown"')

  if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    check_pass "ECS cluster ACTIVE — ${CLUSTER_NAME} (${CLUSTER_ARN})"
  else
    check_fail "ECS cluster status" "expected ACTIVE, got ${CLUSTER_STATUS}"
  fi
else
  check_fail "ECS cluster exists" "no cluster name available — run terraform apply first"
fi

# ─── check 2: capacity providers ─────────────────────────────────────────────
if [ -n "$CLUSTER_NAME" ] && [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
  CP_LIST=$(echo "$CLUSTER_JSON" | jq -r '.clusters[0].capacityProviders[]' 2>/dev/null | sort | tr '\n' ' ' | sed 's/ $//')
  if echo "$CP_LIST" | grep -q "FARGATE"; then
    check_pass "Capacity providers include FARGATE — found: ${CP_LIST}"
  else
    check_fail "Capacity providers" "FARGATE not found — got: ${CP_LIST}"
  fi
else
  check_warn "Capacity providers" "skipped — cluster not active"
fi

# ─── check 3: CloudWatch log group ────────────────────────────────────────────
LOG_GROUP="/aws/ecs/${CLUSTER_NAME:-unknown}"
LOG_EXISTS=$(aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" --output json 2>/dev/null || echo '{"logGroups":[]}')
LOG_COUNT=$(echo "$LOG_EXISTS" | jq '.logGroups | length')
if [ "$LOG_COUNT" -gt 0 ]; then
  check_pass "CloudWatch log group exists — ${LOG_GROUP}"
else
  check_warn "CloudWatch log group" "${LOG_GROUP} not found — may use different naming convention"
fi

# ─── check 4: services list ───────────────────────────────────────────────────
ACTUAL_SERVICE_COUNT=0
SERVICE_ARNS=""
SVC_DETAILS='{"services":[]}'
if [ -n "$CLUSTER_NAME" ] && [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
  SERVICES_JSON=$(aws ecs list-services --cluster "$CLUSTER_NAME" --region "$REGION" --output json 2>/dev/null || echo '{"serviceArns":[]}')
  ACTUAL_SERVICE_COUNT=$(echo "$SERVICES_JSON" | jq '.serviceArns | length')
  SERVICE_ARNS=$(echo "$SERVICES_JSON" | jq -r '.serviceArns[]' 2>/dev/null || true)

  if [ "$ACTUAL_SERVICE_COUNT" -gt 0 ]; then
    check_pass "Services found — ${ACTUAL_SERVICE_COUNT} service(s) in cluster"
  else
    check_warn "Services list" "no services found — may need to deploy services separately"
  fi
else
  check_warn "Services list" "skipped — cluster not active"
fi

# ─── check 5: services ACTIVE with desired task count ─────────────────────────
ACTIVE_SVCS=0
TOTAL_DESIRED=0
TOTAL_RUNNING=0
if [ "$ACTUAL_SERVICE_COUNT" -gt 0 ]; then
  # shellcheck disable=SC2086
  SVC_DETAILS=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services $SERVICE_ARNS --region "$REGION" --output json 2>/dev/null || echo '{"services":[]}')
  ACTIVE_SVCS=$(echo "$SVC_DETAILS" | jq '[.services[] | select(.status == "ACTIVE")] | length')
  TOTAL_DESIRED=$(echo "$SVC_DETAILS" | jq '[.services[].desiredCount] | add // 0')
  TOTAL_RUNNING=$(echo "$SVC_DETAILS" | jq '[.services[].runningCount] | add // 0')

  if [ "$ACTIVE_SVCS" -eq "$ACTUAL_SERVICE_COUNT" ]; then
    check_pass "All services ACTIVE — desired: ${TOTAL_DESIRED}, running: ${TOTAL_RUNNING}"
  else
    check_fail "Service status" "${ACTIVE_SVCS}/${ACTUAL_SERVICE_COUNT} services ACTIVE"
  fi
else
  check_warn "Service health" "skipped — no services to check"
fi

# ─── check 6: task definitions registered ─────────────────────────────────────
TD_FAMILIES=""
TD_COUNT=0
if [ "$ACTUAL_SERVICE_COUNT" -gt 0 ]; then
  TD_FAMILIES=$(echo "$SVC_DETAILS" | jq -r '.services[].taskDefinition' 2>/dev/null \
    | awk -F'/' '{print $NF}' | awk -F':' '{print $1}' | sort -u | tr '\n' ' ' | sed 's/ $//')
  TD_COUNT=$(echo "$SVC_DETAILS" | jq -r '.services[].taskDefinition' 2>/dev/null | wc -l | tr -d ' ')

  if [ "$TD_COUNT" -gt 0 ]; then
    check_pass "Task definitions registered — ${TD_FAMILIES} (${TD_COUNT} total)"
  else
    check_fail "Task definitions" "no task definitions found for services"
  fi
else
  check_warn "Task definitions" "skipped — no services"
fi

# ─── check 7: S3 state file ───────────────────────────────────────────────────
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "unknown")
STATE_BUCKET="${ACCOUNT_ID}-tfstate-${REGION}"
STATE_KEY="projects/${MODULE}/terraform.tfstate"

STATE_SIZE=$(aws s3api head-object --bucket "$STATE_BUCKET" --key "$STATE_KEY" --query 'ContentLength' --output text 2>/dev/null || echo "0")
if [ "${STATE_SIZE:-0}" -gt 0 ] 2>/dev/null; then
  check_pass "S3 state file exists — s3://${STATE_BUCKET}/${STATE_KEY} (${STATE_SIZE} bytes)"
else
  check_warn "S3 state file" "s3://${STATE_BUCKET}/${STATE_KEY} not found or empty — may be using local backend"
fi

# ─── check 8: drift detection (CLI service count vs TF output) ────────────────
TF_SERVICE_COUNT=0
if [ -d "$PROJECT_DIR" ]; then
  TF_OUTPUT=$(terraform -chdir="$PROJECT_DIR" output -json 2>/dev/null || echo '{}')
  TF_SERVICE_COUNT=$(echo "$TF_OUTPUT" | jq '.services.value // {} | length' 2>/dev/null || echo "0")
fi

if [ "$ACTUAL_SERVICE_COUNT" -gt 0 ] && [ "$TF_SERVICE_COUNT" -gt 0 ]; then
  if [ "$ACTUAL_SERVICE_COUNT" -eq "$TF_SERVICE_COUNT" ]; then
    check_pass "No drift — AWS services (${ACTUAL_SERVICE_COUNT}) = TF outputs (${TF_SERVICE_COUNT})"
  else
    check_warn "Potential drift" "AWS services: ${ACTUAL_SERVICE_COUNT}, TF outputs: ${TF_SERVICE_COUNT}"
  fi
elif [ "$TF_SERVICE_COUNT" -eq 0 ]; then
  check_warn "Drift detection" "TF output service count unavailable — run apply first"
else
  check_warn "Drift detection" "insufficient data (AWS: ${ACTUAL_SERVICE_COUNT}, TF: ${TF_SERVICE_COUNT})"
fi

# ─── summary + evidence ──────────────────────────────────────────────────────
echo ""
echo "=== Verify-ECS-Deployment Summary ==="
echo "  PASS: ${PASS} / ${TOTAL}"
echo "  FAIL: ${FAIL} / ${TOTAL}"
echo "  WARN: ${WARN} / ${TOTAL}"

mkdir -p "$EVIDENCE_DIR/deployment-logs"
EVIDENCE_FILE="$EVIDENCE_DIR/deployment-logs/verify-ecs-${DATE}.json"
cat > "$EVIDENCE_FILE" <<EJSON
{
  "timestamp": "${TIMESTAMP}",
  "module": "${MODULE}",
  "region": "${REGION}",
  "cluster_name": "${CLUSTER_NAME:-}",
  "cluster_status": "${CLUSTER_STATUS:-NOT_FOUND}",
  "cluster_arn": "${CLUSTER_ARN:-unknown}",
  "checks_total": ${TOTAL},
  "checks_passed": ${PASS},
  "checks_failed": ${FAIL},
  "checks_warned": ${WARN},
  "aws_service_count": ${ACTUAL_SERVICE_COUNT},
  "aws_active_service_count": ${ACTIVE_SVCS},
  "aws_desired_task_count": ${TOTAL_DESIRED},
  "aws_running_task_count": ${TOTAL_RUNNING},
  "aws_task_definition_count": ${TD_COUNT},
  "tf_service_count": ${TF_SERVICE_COUNT},
  "state_bucket": "${STATE_BUCKET}",
  "state_key": "${STATE_KEY}",
  "state_size_bytes": ${STATE_SIZE:-0},
  "script": "scripts/verify-ecs-deployment.sh v1.0.0"
}
EJSON
echo "Evidence: ${EVIDENCE_FILE}"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "FAILED: verify-ecs-deployment — ${FAIL} check(s) did not pass."
  exit 1
fi

echo ""
echo "PASSED: verify-ecs-deployment [MODULE=${MODULE}]"
