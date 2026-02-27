#!/bin/bash
set -euo pipefail

# Verify 7 evidence directories exist (anti-NATO gate)
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"

PASS=0; FAIL=0
for dir in coordination-logs test-results security-scans cost-reports legal-audit evidence governance; do
  if [ -d "$EVIDENCE_DIR/$dir" ]; then
    PASS=$((PASS+1))
  else
    echo "MISSING: $EVIDENCE_DIR/$dir"
    FAIL=$((FAIL+1))
  fi
done

echo "Evidence: $PASS present, $FAIL missing"
[ $FAIL -eq 0 ] || exit 1
