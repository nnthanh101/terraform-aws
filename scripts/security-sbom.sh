#!/bin/bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
set -euo pipefail

# CycloneDX SBOM generation per module -> $EVIDENCE_DIR/security-scans/
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/security-scans"

if ! command -v trivy >/dev/null 2>&1; then
  if [ -n "${CI:-}" ]; then
    echo "FAIL: trivy not installed in CI" && exit 1
  fi
  echo "SKIP: trivy not installed (https://aquasecurity.github.io/trivy/)"
  exit 0
fi

MODULE="${MODULE:-iam-identity-center}"
MODULE_DIR="${MODULE_DIR:-modules/${MODULE}}"

SCAN_PASS=true
for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"*.tf 1>/dev/null 2>&1; then
    MODULE_NAME=$(basename "$dir")
    OUTPUT="$EVIDENCE_DIR/security-scans/sbom-${MODULE_NAME}-$(date +%Y-%m-%d).json"
    echo "Generating SBOM for $dir..."
    trivy fs --format cyclonedx \
      --output "$OUTPUT" \
      "$dir" || SCAN_PASS=false
    echo "  -> $OUTPUT"
  fi
done

if [ "$SCAN_PASS" = "true" ]; then
  echo "PASSED: security:sbom"
else
  echo "WARN: security:sbom encountered errors (see $EVIDENCE_DIR/security-scans/)"
  exit 1
fi
