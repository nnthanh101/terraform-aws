#!/bin/bash
set -euo pipefail

# Trivy IaC misconfig scanning per module -> $EVIDENCE_DIR/security-scans/
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/security-scans"

if ! command -v trivy >/dev/null 2>&1; then
  if [ -n "${CI:-}" ]; then
    echo "FAIL: trivy not installed in CI" && exit 1
  fi
  echo "SKIP: trivy not installed (https://aquasecurity.github.io/trivy/)"
  exit 0
fi

SCAN_PASS=true
for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
    MODULE=$(basename "$dir")
    echo "Scanning $dir..."
    trivy fs --scanners misconfig --format json \
      --output "$EVIDENCE_DIR/security-scans/trivy-${MODULE}.json" \
      "$dir" || SCAN_PASS=false
  fi
done

if [ "$SCAN_PASS" = "true" ]; then
  echo "PASSED: security:trivy"
else
  echo "WARN: security:trivy found issues (see $EVIDENCE_DIR/security-scans/)"
  exit 1
fi
