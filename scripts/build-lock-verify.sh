#!/bin/bash
set -euo pipefail

# Verify .terraform.lock.hcl exists for every module with .tf files
MISSING=0
for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
    if [ ! -f "$dir/.terraform.lock.hcl" ]; then
      echo "MISSING: $dir/.terraform.lock.hcl"
      MISSING=$((MISSING+1))
    fi
  fi
done

if [ $MISSING -gt 0 ]; then
  echo "FAIL: $MISSING module(s) missing .terraform.lock.hcl"
  echo "Run: task build:lock"
  exit 1
fi

echo "PASSED: All modules have .terraform.lock.hcl"
