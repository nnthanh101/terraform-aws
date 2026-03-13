#!/bin/bash
set -euo pipefail

# terraform fmt -check + validate (no credentials needed)
# Scope: modules/ only (projects/ contains consumer backend config that requires credentials)

MODULE_DIR="${MODULE_DIR:-}"

if [ -n "$MODULE_DIR" ] && [ -d "$MODULE_DIR" ]; then
  # Single-module mode: validate specific module
  terraform fmt -check "$MODULE_DIR"
  # Skip validate for modules with configuration_aliases (requires provider alias at plan time)
  if grep -rq 'configuration_aliases' "$MODULE_DIR"/versions.tf 2>/dev/null; then
    echo "Skipping validate for ${MODULE_DIR}/ (configuration_aliases — requires provider alias at apply time)"
  else
    echo "Validating ${MODULE_DIR}/..."
    (cd "$MODULE_DIR" && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate)
  fi
else
  # All-modules mode: validate all modules under modules/
  for dir in modules/*/; do
    if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
      terraform fmt -check "$dir"
      echo "Validating $dir..."
      (cd "$dir" && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate)
    fi
  done
fi

echo "PASSED: build:validate"
