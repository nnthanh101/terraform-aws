#!/bin/bash
set -euo pipefail
# validate-sprint1.sh — Sprint milestone gate (DRY: delegates to Taskfile tasks)
# Usage: task sprint:validate  OR  ./scripts/validate-sprint1.sh

EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
[[ "$EVIDENCE_DIR" = /* ]] || EVIDENCE_DIR="$(pwd)/$EVIDENCE_DIR"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PASS=0; FAIL=0; TOTAL=5

gate() {
  local name="$1"; shift
  if "$@" > /dev/null 2>&1; then
    printf "  %-40s [PASS]\n" "$name"; PASS=$((PASS+1))
  else
    printf "  %-40s [FAIL]\n" "$name"; FAIL=$((FAIL+1))
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
echo "  Result: $PASS/$TOTAL gates passed"
echo ""

mkdir -p "$EVIDENCE_DIR/evidence"
cat > "$EVIDENCE_DIR/evidence/sprint-validation.json" <<EOF
{"date":"$TIMESTAMP","gates":$TOTAL,"passed":$PASS,"failed":$FAIL,"result":"$([ $FAIL -eq 0 ] && echo "PASS" || echo "FAIL")"}
EOF

[ $FAIL -eq 0 ] && exit 0 || exit 1
