#!/bin/bash
set -euo pipefail
# validate-sprint.sh — Sprint milestone gate (DRY: delegates to Taskfile tasks)
# Usage: task sprint:validate  OR  ./scripts/validate-sprint.sh
# Sprint-agnostic: gates are systemic quality checks, not deliverable-specific

EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
[[ "$EVIDENCE_DIR" = /* ]] || EVIDENCE_DIR="$(pwd)/$EVIDENCE_DIR"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PASS=0; FAIL=0; TOTAL=5; WARN=0

gate() {
  local name="$1"; shift
  if "$@" > /dev/null 2>&1; then
    printf "  %-40s [PASS]\n" "$name"; PASS=$((PASS+1))
  else
    printf "  %-40s [FAIL]\n" "$name"; FAIL=$((FAIL+1))
  fi
}

advisory() {
  local name="$1"; shift
  if "$@" > /dev/null 2>&1; then
    printf "  %-40s [PASS]\n" "$name (advisory)"
  else
    printf "  %-40s [WARN]\n" "$name (advisory)"; WARN=$((WARN+1))
  fi
}

echo ""
echo "  Sprint Validation — terraform-aws ($TIMESTAMP)"
echo "  ─────────────────────────────────────────────────"
echo ""

gate "1. CI quick (fmt + lint + legal)"    task ci:quick
gate "2. Tier 1 tests (.tftest.hcl)"       task test:tier1
gate "3. Cost estimation (infracost)"       task plan:cost
gate "4. Governance score (>=85%)"          task govern:score
gate "5. Evidence dirs (anti-NATO)"         task monitor:verify

echo ""

# Advisory gates (WARN, not FAIL)
advisory "A1. Tier 2 LocalStack tests"     test -d tests/localstack -a -n "$(ls tests/localstack/*.go 2>/dev/null)"
advisory "A2. Coordination log (PO today)"   test -n "$(ls "$EVIDENCE_DIR"/coordination-logs/product-owner-"$(date +%Y-%m-%d)"*.json 2>/dev/null)"

echo ""
echo "  Result: $PASS/$TOTAL gates passed, $WARN advisory warnings"
echo ""

mkdir -p "$EVIDENCE_DIR/evidence"
cat > "$EVIDENCE_DIR/evidence/sprint-validation.json" <<EOF
{"date":"$TIMESTAMP","gates":$TOTAL,"passed":$PASS,"failed":$FAIL,"warnings":$WARN,"result":"$([ $FAIL -eq 0 ] && echo "PASS" || echo "FAIL")"}
EOF

[ $FAIL -eq 0 ] && exit 0 || exit 1
