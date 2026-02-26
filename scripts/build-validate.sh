#!/bin/bash
set -euo pipefail

# terraform fmt -check + validate all modules (no credentials needed)
terraform fmt -check -recursive .

for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
    echo "Validating $dir..."
    (cd "$dir" && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate)
  fi
done

echo "PASSED: build:validate"
