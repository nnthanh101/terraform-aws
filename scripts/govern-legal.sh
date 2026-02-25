#!/bin/bash
set -euo pipefail

# Apache 2.0 compliance audit (4 checks) -> $EVIDENCE_DIR/legal/audit.json
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/legal"

PASS=0; FAIL=0; TOTAL=4
echo "=== Legal Compliance Audit ==="

# Check 1: LICENSE file
if [ -f LICENSE ] && grep -q "Apache License" LICENSE; then
  echo "CHECK 1/4: LICENSE file (Apache 2.0) ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 1/4: LICENSE file (Apache 2.0) ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 2: NOTICE file
if [ -f NOTICE ] && grep -q "Copyright" NOTICE; then
  echo "CHECK 2/4: NOTICE file ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 2/4: NOTICE file ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 3: No incompatible licenses
GPL_FILES=""
GPL_FILES=$(grep -rl "GPL" modules/ tests/ examples/ --include="*.tf" --include="*.go" 2>/dev/null) || true
if [ -z "$GPL_FILES" ]; then
  echo "CHECK 3/4: No incompatible licenses ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 3/4: No incompatible licenses ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 4: VERSION file
if [ -f VERSION ]; then
  echo "CHECK 4/4: VERSION file ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 4/4: VERSION file ... FAILED"
  FAIL=$((FAIL+1))
fi

echo ""
echo "Result: $PASS/$TOTAL PASSED"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"checks\":$TOTAL,\"passed\":$PASS,\"failed\":$FAIL}" \
  > "$EVIDENCE_DIR/legal/audit.json"

if [ $FAIL -gt 0 ]; then exit 1; fi
