#!/bin/bash
set -euo pipefail

# Constitutional checkpoint scoring (10 checks, >=85%) -> $EVIDENCE_DIR/governance/score.json
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/governance"

SCORE=0; TOTAL=10
echo "=== Governance Score ==="

[ -d .adlc ] && SCORE=$((SCORE+1)) && echo "CP-1: ADLC submodule ... PASS" || echo "CP-1: ADLC submodule ... FAIL"
[ -L .claude ] && [ -f .claude/settings.json ] && SCORE=$((SCORE+1)) && echo "CP-2: .claude symlink ... PASS" || echo "CP-2: .claude symlink ... FAIL"
[ -L .specify ] && [ -f .specify/memory/constitution.md ] && SCORE=$((SCORE+1)) && echo "CP-3: .specify symlink ... PASS" || echo "CP-3: .specify symlink ... FAIL"
[ -f LICENSE ] && SCORE=$((SCORE+1)) && echo "CP-4: LICENSE file ... PASS" || echo "CP-4: LICENSE file ... FAIL"
[ -f NOTICE ] && SCORE=$((SCORE+1)) && echo "CP-5: NOTICE file ... PASS" || echo "CP-5: NOTICE file ... FAIL"
[ -f VERSION ] && SCORE=$((SCORE+1)) && echo "CP-6: VERSION file ... PASS" || echo "CP-6: VERSION file ... FAIL"
[ -f CLAUDE.md ] && SCORE=$((SCORE+1)) && echo "CP-7: CLAUDE.md ... PASS" || echo "CP-7: CLAUDE.md ... FAIL"
[ -f Taskfile.yml ] && SCORE=$((SCORE+1)) && echo "CP-8: Taskfile.yml ... PASS" || echo "CP-8: Taskfile.yml ... FAIL"
[ -d modules/identity-center ] && [ -d modules/ecs-platform ] && [ -d modules/fullstack-web ] && SCORE=$((SCORE+1)) && echo "CP-9: Module dirs ... PASS" || echo "CP-9: Module dirs ... FAIL"
[ -d tests/snapshot ] && [ -d tests/localstack ] && [ -d tests/integration ] && SCORE=$((SCORE+1)) && echo "CP-10: Test dirs ... PASS" || echo "CP-10: Test dirs ... FAIL"

PERCENT=$(( SCORE * 100 / TOTAL ))
echo ""
echo "Governance Score: $SCORE/$TOTAL ($PERCENT%)"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"score\":$SCORE,\"total\":$TOTAL,\"percent\":$PERCENT}" \
  > "$EVIDENCE_DIR/governance/score.json"

if [ $PERCENT -lt 85 ]; then
  echo "FAIL: Governance score $PERCENT% below 85% threshold" && exit 1
fi
echo "PASSED: govern:score ($PERCENT% >= 85%)"
