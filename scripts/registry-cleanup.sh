#!/bin/bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# registry-cleanup.sh — Delete old TFC module versions, keep only specified version
#
# Usage:
#   TFE_TOKEN=xxx MODULE=iam-identity-center KEEP_VERSION=1.2.0 bash scripts/registry-cleanup.sh
#
# TFC API: DELETE /api/v2/organizations/:org/registry-modules/private/:org/:name/:provider/:version
#
set -euo pipefail

MODULE="${MODULE:?MODULE required (e.g., iam-identity-center)}"
KEEP_VERSION="${KEEP_VERSION:?KEEP_VERSION required (e.g., 1.2.0)}"
TFE_TOKEN="${TFE_TOKEN:?TFE_TOKEN required}"
ORG="${TFC_ORG:-oceansoft}"
PROVIDER="${TFC_PROVIDER:-aws}"
DRY_RUN="${DRY_RUN:-false}"

# Input validation (Red Team F-05: prevent path traversal in API URLs)
[[ "$MODULE" =~ ^[a-z][a-z0-9-]+$ ]] || { echo "ERROR: MODULE must be kebab-case (got: '$MODULE')"; exit 1; }
[[ "$KEEP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "ERROR: KEEP_VERSION must be semver (got: '$KEEP_VERSION')"; exit 1; }
[[ "$ORG" =~ ^[a-zA-Z][a-zA-Z0-9-]+$ ]] || { echo "ERROR: ORG contains invalid chars (got: '$ORG')"; exit 1; }
[[ "$PROVIDER" =~ ^[a-z]+$ ]] || { echo "ERROR: PROVIDER contains invalid chars (got: '$PROVIDER')"; exit 1; }

API_BASE="https://app.terraform.io/api/v2/organizations/${ORG}/registry-modules/private/${ORG}/${MODULE}/${PROVIDER}"

echo "=== TFC Registry Cleanup ==="
echo "Module: ${ORG}/${MODULE}/${PROVIDER}"
echo "Keep:   v${KEEP_VERSION}"
echo "Dry run: ${DRY_RUN}"
echo ""

# List all versions
VERSIONS_JSON=$(curl -s \
  -H "Authorization: Bearer ${TFE_TOKEN}" \
  "${API_BASE}")

VERSIONS=$(echo "$VERSIONS_JSON" | jq -r '.data.attributes."version-statuses"[].version' 2>/dev/null)

if [ -z "$VERSIONS" ]; then
  echo "ERROR: No versions found or API call failed"
  echo "API error: $(echo "$VERSIONS_JSON" | jq -r '.errors[0].detail // "unknown"' 2>/dev/null)"
  exit 1
fi

echo "Found versions:"
echo "$VERSIONS" | sed 's/^/  /'
echo ""

DELETED=0
KEPT=0
FAILED=0

for VERSION in $VERSIONS; do
  if [ "$VERSION" = "$KEEP_VERSION" ]; then
    echo "KEEP:   v${VERSION}"
    KEPT=$((KEPT + 1))
    continue
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "DELETE: v${VERSION} (dry run — skipped)"
    DELETED=$((DELETED + 1))
    continue
  fi

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X DELETE \
    -H "Authorization: Bearer ${TFE_TOKEN}" \
    -H "Content-Type: application/vnd.api+json" \
    "${API_BASE}/${VERSION}")

  if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "DELETE: v${VERSION} (HTTP ${HTTP_CODE})"
    DELETED=$((DELETED + 1))
  else
    echo "FAIL:   v${VERSION} (HTTP ${HTTP_CODE})"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Result: kept=${KEPT} deleted=${DELETED} failed=${FAILED}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
