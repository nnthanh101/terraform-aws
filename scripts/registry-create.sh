#!/bin/bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# registry-create.sh — Create API-only modules in TFC Private Registry
#
# Usage:
#   TFE_TOKEN=xxx MODULE=ecs bash scripts/registry-create.sh
#   TFE_TOKEN=xxx MODULE=all bash scripts/registry-create.sh   # all modules with .tf files
#
# TFC API: POST /api/v2/organizations/:org/registry-modules
#
set -euo pipefail

MODULE="${MODULE:?MODULE required (e.g., ecs, iam-identity-center, or 'all')}"
TFE_TOKEN="${TFE_TOKEN:?TFE_TOKEN required}"
ORG="${TFC_ORG:-oceansoft}"
PROVIDER="${TFC_PROVIDER:-aws}"
REGISTRY_NAME="${TFC_REGISTRY:-private}"

API_BASE="https://app.terraform.io/api/v2/organizations/${ORG}/registry-modules"

# Input validation
[[ "$ORG" =~ ^[a-zA-Z][a-zA-Z0-9-]+$ ]] || { echo "ERROR: ORG contains invalid chars (got: '$ORG')"; exit 1; }
[[ "$PROVIDER" =~ ^[a-z]+$ ]] || { echo "ERROR: PROVIDER contains invalid chars (got: '$PROVIDER')"; exit 1; }

create_module() {
  local mod_name="$1"
  [[ "$mod_name" =~ ^[a-z][a-z0-9-]+$ ]] || { echo "ERROR: module name must be kebab-case (got: '$mod_name')"; return 1; }

  # Pre-flight: check if module already exists
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${TFE_TOKEN}" \
    "${API_BASE}/${REGISTRY_NAME}/${ORG}/${mod_name}/${PROVIDER}")

  if [ "$HTTP_CODE" = "200" ]; then
    # Check if VCS-connected
    VCS_REPO=$(curl -s \
      -H "Authorization: Bearer ${TFE_TOKEN}" \
      "${API_BASE}/${REGISTRY_NAME}/${ORG}/${mod_name}/${PROVIDER}" \
      | jq -r '.data.attributes."vcs-repo" // empty')
    if [ -n "$VCS_REPO" ] && [ "$VCS_REPO" != "null" ]; then
      echo "WARN: ${mod_name} exists but is VCS-connected — delete in TFC console first, then re-run"
      return 1
    fi
    echo "SKIP: ${mod_name} already exists as API-only"
    return 0
  fi

  # Create API-only module (no-code, no VCS)
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer ${TFE_TOKEN}" \
    -H "Content-Type: application/vnd.api+json" \
    -d "{
      \"data\": {
        \"type\": \"registry-modules\",
        \"attributes\": {
          \"name\": \"${mod_name}\",
          \"provider\": \"${PROVIDER}\",
          \"registry-name\": \"${REGISTRY_NAME}\",
          \"no-code\": false
        }
      }
    }" \
    "${API_BASE}")

  RESP_CODE=$(echo "$RESPONSE" | tail -1)
  RESP_BODY=$(echo "$RESPONSE" | sed '$d')

  if [ "$RESP_CODE" = "201" ]; then
    echo "OK:   ${mod_name} created as API-only (${ORG}/${mod_name}/${PROVIDER})"
    return 0
  else
    API_ERROR=$(echo "$RESP_BODY" | jq -r '.errors[0].detail // "unknown"' 2>/dev/null)
    echo "FAIL: ${mod_name} (HTTP ${RESP_CODE}) — ${API_ERROR}"
    return 1
  fi
}

echo "=== TFC Registry Create (API-only) ==="
echo "Org:      ${ORG}"
echo "Provider: ${PROVIDER}"
echo ""

CREATED=0
SKIPPED=0
FAILED=0

if [ "$MODULE" = "all" ]; then
  # Discover all modules with .tf files
  for MODULE_DIR in modules/*/; do
    MOD_NAME=$(basename "$MODULE_DIR")
    if ! ls "${MODULE_DIR}"*.tf >/dev/null 2>&1; then
      echo "SKIP: ${MOD_NAME} (no .tf files — stub)"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
    if create_module "$MOD_NAME"; then
      CREATED=$((CREATED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  done
else
  if create_module "$MODULE"; then
    CREATED=$((CREATED + 1))
  else
    FAILED=$((FAILED + 1))
  fi
fi

echo ""
echo "Result: created/ok=${CREATED} skipped=${SKIPPED} failed=${FAILED}"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
