#!/bin/bash
set -euo pipefail

# terraform-docs README generation for all modules
if ! command -v terraform-docs >/dev/null 2>&1; then
  echo "SKIP: terraform-docs not installed (go install github.com/terraform-docs/terraform-docs@latest)"
  exit 0
fi

for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
    echo "Generating docs for $dir..."
    terraform-docs markdown table --output-file README.md --output-mode inject "$dir" 2>/dev/null \
      || terraform-docs markdown table "$dir" > "${dir}README.md"
  fi
done

echo "PASSED: build:docs"
