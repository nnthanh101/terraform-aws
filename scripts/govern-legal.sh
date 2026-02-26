#!/bin/bash
set -euo pipefail

# Apache 2.0 compliance audit (5 checks) -> $EVIDENCE_DIR/legal-audit/audit.json
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/legal-audit"

PASS=0; FAIL=0; TOTAL=5
echo "=== Legal Compliance Audit ==="

# Check 1: LICENSE file
if [ -f LICENSE ] && grep -q "Apache License" LICENSE; then
  echo "CHECK 1/$TOTAL: LICENSE file (Apache 2.0) ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 1/$TOTAL: LICENSE file (Apache 2.0) ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 2: NOTICE file with upstream cross-reference
NOTICE_OK=true
if [ -f NOTICE ] && grep -q "Copyright" NOTICE; then
  # Cross-reference: every module source= must have matching NOTICE entry
  for dir in modules/*/; do
    [ -f "$dir/main.tf" ] || continue
    SOURCE=$(grep -oP 'source\s*=\s*"\K[^"]+' "$dir/main.tf" 2>/dev/null | head -1) || true
    if [ -n "$SOURCE" ]; then
      # Extract org/repo pattern (e.g., aws-samples from "aws-samples/identity-center/aws")
      ORG=$(echo "$SOURCE" | cut -d'/' -f1)
      if ! grep -q "$ORG" NOTICE 2>/dev/null; then
        echo "  WARN: $dir uses source '$SOURCE' but '$ORG' not in NOTICE"
        NOTICE_OK=false
      fi
    fi
  done
  if [ "$NOTICE_OK" = "true" ]; then
    echo "CHECK 2/$TOTAL: NOTICE file + upstream cross-ref ... PASSED"
    PASS=$((PASS+1))
  else
    echo "CHECK 2/$TOTAL: NOTICE file + upstream cross-ref ... FAILED"
    FAIL=$((FAIL+1))
  fi
else
  echo "CHECK 2/$TOTAL: NOTICE file ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 3: No incompatible licenses
GPL_FILES=""
GPL_FILES=$(grep -rl "GPL" modules/ tests/ examples/ --include="*.tf" --include="*.go" 2>/dev/null) || true
if [ -z "$GPL_FILES" ]; then
  echo "CHECK 3/$TOTAL: No incompatible licenses ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 3/$TOTAL: No incompatible licenses ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 4: VERSION file
if [ -f VERSION ]; then
  echo "CHECK 4/$TOTAL: VERSION file ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 4/$TOTAL: VERSION file ... FAILED"
  FAIL=$((FAIL+1))
fi

# Check 5: Copyright headers on all .tf files in modules/
MISSING_HEADERS=""
for tf_file in modules/*/*.tf; do
  [ -f "$tf_file" ] || continue
  if ! head -1 "$tf_file" | grep -q "^# Copyright"; then
    MISSING_HEADERS="$MISSING_HEADERS $tf_file"
  fi
done
if [ -z "$MISSING_HEADERS" ]; then
  echo "CHECK 5/$TOTAL: Copyright headers on .tf files ... PASSED"
  PASS=$((PASS+1))
else
  echo "CHECK 5/$TOTAL: Copyright headers on .tf files ... FAILED"
  echo "  Missing headers:$MISSING_HEADERS"
  FAIL=$((FAIL+1))
fi

echo ""
echo "Result: $PASS/$TOTAL PASSED"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"checks\":$TOTAL,\"passed\":$PASS,\"failed\":$FAIL}" \
  > "$EVIDENCE_DIR/legal-audit/audit.json"

if [ $FAIL -gt 0 ]; then exit 1; fi
