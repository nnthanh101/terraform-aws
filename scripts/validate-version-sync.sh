#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# validate-version-sync.sh — Pre-publish 4-file version consistency check.
#
# Prevents VERSION_DRIFT_SILENT_FAIL: release-please's `simple` updater
# silently skips VERSION files whose content doesn't match the manifest.
# This script catches drift before it ships.
#
# Checks:
#   1. modules/<module>/VERSION
#   2. .release-please-manifest.json
#   3. modules/<module>/CHANGELOG.md (latest ## [x.y.z] header)
#   4. projects/<module>/main.tf (source ref tag, optional)
#
# Usage:
#   bash scripts/validate-version-sync.sh iam-identity-center
#   MODULE=iam-identity-center bash scripts/validate-version-sync.sh
#
# Exit codes:
#   0 — all version references match
#   1 — one or more mismatches detected

set -euo pipefail

MODULE="${1:-${MODULE:-}}"
if [ -z "$MODULE" ]; then
  echo "Usage: validate-version-sync.sh <module-name>" >&2
  echo "  or: MODULE=<module-name> bash scripts/validate-version-sync.sh" >&2
  exit 1
fi

MODULE_DIR="modules/${MODULE}"
PROJECT_DIR="projects/${MODULE}"

echo "=== govern:version-sync [MODULE=${MODULE}] ==="

# ─── 1. Read VERSION file ──────────────────────────────────────────────────
if [ ! -f "${MODULE_DIR}/VERSION" ]; then
  echo "FAIL: ${MODULE_DIR}/VERSION not found" >&2
  exit 1
fi
VERSION_FILE=$(cat "${MODULE_DIR}/VERSION" | tr -d '[:space:]')
echo "  VERSION file:  ${VERSION_FILE}"

# ─── 2. Read manifest ──────────────────────────────────────────────────────
if [ ! -f ".release-please-manifest.json" ]; then
  echo "FAIL: .release-please-manifest.json not found" >&2
  exit 1
fi
MANIFEST_VERSION=$(jq -r ".\"${MODULE_DIR}\"" .release-please-manifest.json)
if [ "$MANIFEST_VERSION" = "null" ] || [ -z "$MANIFEST_VERSION" ]; then
  echo "FAIL: Module '${MODULE_DIR}' not found in .release-please-manifest.json" >&2
  exit 1
fi
echo "  Manifest:      ${MANIFEST_VERSION}"

# ─── 3. Read CHANGELOG latest header ───────────────────────────────────────
CHANGELOG_VERSION=""
if [ -f "${MODULE_DIR}/CHANGELOG.md" ]; then
  CHANGELOG_VERSION=$(grep -m1 '^## \[' "${MODULE_DIR}/CHANGELOG.md" | sed 's/## \[\(.*\)\].*/\1/' || echo "")
fi
if [ -n "$CHANGELOG_VERSION" ]; then
  echo "  CHANGELOG:     ${CHANGELOG_VERSION}"
else
  echo "  CHANGELOG:     (not found or empty — advisory)"
fi

# ─── 4. Read main.tf source ref (optional) ─────────────────────────────────
MAIN_TF_VERSION=""
if [ -f "${PROJECT_DIR}/main.tf" ]; then
  MAIN_TF_VERSION=$(grep "ref=${MODULE}/v" "${PROJECT_DIR}/main.tf" 2>/dev/null | sed "s/.*ref=${MODULE}\/v//" | sed 's/".*//' || echo "")
fi
if [ -n "$MAIN_TF_VERSION" ]; then
  echo "  main.tf ref:   ${MAIN_TF_VERSION}"
else
  echo "  main.tf ref:   (not found — advisory)"
fi

# ─── Compare ────────────────────────────────────────────────────────────────
ERRORS=0

if [ "$VERSION_FILE" != "$MANIFEST_VERSION" ]; then
  echo "MISMATCH: VERSION ($VERSION_FILE) != manifest ($MANIFEST_VERSION)" >&2
  ERRORS=$((ERRORS + 1))
fi

if [ -n "$CHANGELOG_VERSION" ] && [ "$VERSION_FILE" != "$CHANGELOG_VERSION" ]; then
  echo "MISMATCH: VERSION ($VERSION_FILE) != CHANGELOG ($CHANGELOG_VERSION)" >&2
  ERRORS=$((ERRORS + 1))
fi

if [ -n "$MAIN_TF_VERSION" ] && [ "$VERSION_FILE" != "$MAIN_TF_VERSION" ]; then
  echo "MISMATCH: VERSION ($VERSION_FILE) != main.tf ref ($MAIN_TF_VERSION)" >&2
  ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "FAIL: ${ERRORS} version mismatch(es) detected" >&2
  exit 1
fi

echo ""
echo "PASS: All version references = ${VERSION_FILE}"
