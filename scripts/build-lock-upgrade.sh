#!/bin/bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# build-lock-upgrade.sh — S8a: upgrade providers to latest in-constraint + re-lock 4 platforms
# Blog: Section 3 "Team Collaboration Safeguards" → Safeguard #2 + #8
# ADR-003: >= 6.28, < 7.0 | ADR-006: use_lockfile = true
set -euo pipefail

PLATFORMS="linux_amd64 linux_arm64 darwin_amd64 darwin_arm64"
LOCK_ARGS=""
for p in $PLATFORMS; do LOCK_ARGS="$LOCK_ARGS -platform=$p"; done

LOG_DIR="tmp/terraform-aws/lock-upgrade"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/lock-upgrade-$(date +%Y-%m-%d).log"

UPGRADED=0; FAILED=0; SKIPPED=0

echo "=== Provider Lock Upgrade ($(date -u +%Y-%m-%dT%H:%M:%SZ)) ===" | tee "$LOG"

for dir in modules/*/; do
  [ -d "$dir" ] || continue
  ls "$dir"/*.tf 1>/dev/null 2>&1 || { SKIPPED=$((SKIPPED+1)); continue; }
  MODULE=$(basename "$dir")
  echo ">>> $MODULE: terraform init -upgrade" | tee -a "$LOG"
  if ! (cd "$dir" && terraform init -upgrade -backend=false -input=false 2>&1 | tee -a "../../$LOG"); then
    echo "FAIL: $MODULE init -upgrade" | tee -a "$LOG"; FAILED=$((FAILED+1)); continue
  fi
  echo ">>> $MODULE: providers lock (4 platforms)" | tee -a "$LOG"
  if ! (cd "$dir" && terraform providers lock $LOCK_ARGS 2>&1 | tee -a "../../$LOG"); then
    echo "FAIL: $MODULE providers lock" | tee -a "$LOG"; FAILED=$((FAILED+1)); continue
  fi
  UPGRADED=$((UPGRADED+1))
  echo "PASS: $MODULE" | tee -a "$LOG"
done

echo "" | tee -a "$LOG"
echo "Summary: $UPGRADED upgraded, $SKIPPED skipped (no .tf), $FAILED failed" | tee -a "$LOG"
[ "$FAILED" -gt 0 ] && { echo "FAIL: build:lock-upgrade"; exit 1; }
echo "PASSED: build:lock-upgrade" | tee -a "$LOG"
