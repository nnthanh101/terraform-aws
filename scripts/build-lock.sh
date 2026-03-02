#!/bin/bash
set -euo pipefail

# terraform providers lock (4 platforms) -> .terraform.lock.hcl per module
PLATFORMS="linux_amd64 linux_arm64 darwin_amd64 darwin_arm64"
LOCK_ARGS=""
for p in $PLATFORMS; do LOCK_ARGS="$LOCK_ARGS -platform=$p"; done

for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
    echo "Locking providers for $dir..."
    (cd "$dir" && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform providers lock $LOCK_ARGS)
  fi
done

echo "PASSED: build:lock"
