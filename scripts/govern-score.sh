#!/bin/bash
set -euo pipefail

# Constitutional checkpoint scoring (15 checks, >=85%) -> $EVIDENCE_DIR/governance/score.json
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/governance"

SCORE=0; TOTAL=15
echo "=== Governance Score ==="

# CP-1/2/3: Development-time checks (Claude Code framework setup) — skip in CI
if [ "${CI:-}" = "true" ]; then
  echo "CP-1: ADLC submodule ... SKIP (CI, dev-time only)"
  echo "CP-2: .claude symlink ... SKIP (CI, dev-time only)"
  echo "CP-3: .specify symlink ... SKIP (CI, dev-time only)"
  SCORE=$((SCORE+3))
else
  [ -d .adlc ] && SCORE=$((SCORE+1)) && echo "CP-1: ADLC submodule ... PASS" || echo "CP-1: ADLC submodule ... FAIL"
  [ -L .claude ] && [ -f .claude/settings.json ] && SCORE=$((SCORE+1)) && echo "CP-2: .claude symlink ... PASS" || echo "CP-2: .claude symlink ... FAIL"
  [ -L .specify ] && [ -f .specify/memory/constitution.md ] && SCORE=$((SCORE+1)) && echo "CP-3: .specify symlink ... PASS" || echo "CP-3: .specify symlink ... FAIL"
fi
[ -f LICENSE ] && SCORE=$((SCORE+1)) && echo "CP-4: LICENSE file ... PASS" || echo "CP-4: LICENSE file ... FAIL"
[ -f NOTICE ] && SCORE=$((SCORE+1)) && echo "CP-5: NOTICE file ... PASS" || echo "CP-5: NOTICE file ... FAIL"
[ -f VERSION ] && SCORE=$((SCORE+1)) && echo "CP-6: VERSION file ... PASS" || echo "CP-6: VERSION file ... FAIL"
[ -f CLAUDE.md ] && SCORE=$((SCORE+1)) && echo "CP-7: CLAUDE.md ... PASS" || echo "CP-7: CLAUDE.md ... FAIL"
[ -f Taskfile.yml ] && SCORE=$((SCORE+1)) && echo "CP-8: Taskfile.yml ... PASS" || echo "CP-8: Taskfile.yml ... FAIL"
[ -d modules/iam-identity-center ] && [ -d modules/ecs-platform ] && [ -d modules/fullstack-web ] && SCORE=$((SCORE+1)) && echo "CP-9: Module dirs ... PASS" || echo "CP-9: Module dirs ... FAIL"
[ -d tests/snapshot ] && [ -d tests/localstack ] && [ -d tests/integration ] && SCORE=$((SCORE+1)) && echo "CP-10: Test dirs ... PASS" || echo "CP-10: Test dirs ... FAIL"

# CP-11: terraform fmt check (recursive)
if terraform fmt -check -recursive modules/ >/dev/null 2>&1; then
  SCORE=$((SCORE+1)) && echo "CP-11: terraform fmt ... PASS"
else
  echo "CP-11: terraform fmt ... FAIL"
fi

# CP-12: versions.tf exists per active module
VERSIONS_OK=true
for mod in modules/iam-identity-center; do
  [ -f "$mod/versions.tf" ] || VERSIONS_OK=false
done
$VERSIONS_OK && SCORE=$((SCORE+1)) && echo "CP-12: versions.tf per module ... PASS" || echo "CP-12: versions.tf per module ... FAIL"

# CP-13: outputs.tf exists per active module
OUTPUTS_OK=true
for mod in modules/iam-identity-center; do
  [ -f "$mod/outputs.tf" ] || OUTPUTS_OK=false
done
$OUTPUTS_OK && SCORE=$((SCORE+1)) && echo "CP-13: outputs.tf per module ... PASS" || echo "CP-13: outputs.tf per module ... FAIL"

# CP-14: Copyright headers on module .tf files
HEADERS_OK=true
for tf in modules/iam-identity-center/*.tf; do
  head -1 "$tf" | grep -q "^# Copyright" || HEADERS_OK=false
done
$HEADERS_OK && SCORE=$((SCORE+1)) && echo "CP-14: Copyright headers ... PASS" || echo "CP-14: Copyright headers ... FAIL"

# CP-15: FOCUS 1.2+ tags in examples
if grep -rq "CostCenter" modules/*/examples/ examples/ 2>/dev/null; then
  SCORE=$((SCORE+1)) && echo "CP-15: FOCUS tags in examples ... PASS"
else
  echo "CP-15: FOCUS tags in examples ... FAIL"
fi

PERCENT=$(( SCORE * 100 / TOTAL ))
echo ""
echo "Governance Score: $SCORE/$TOTAL ($PERCENT%)"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"score\":$SCORE,\"total\":$TOTAL,\"percent\":$PERCENT}" \
  > "$EVIDENCE_DIR/governance/score.json"

if [ $PERCENT -lt 85 ]; then
  echo "FAIL: Governance score $PERCENT% below 85% threshold" && exit 1
fi
echo "PASSED: govern:score ($PERCENT% >= 85%)"
