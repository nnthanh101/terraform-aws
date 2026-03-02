#!/bin/bash
set -euo pipefail

# tflint + checkov CI-aware linting
# Fail-fast when tools are missing (no SKIP-then-PASS theater)
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/security-scans"
LINT_PASS=true

# tflint: require .tflint.hcl config for real rule execution
if command -v tflint >/dev/null 2>&1; then
  if [ ! -f .tflint.hcl ]; then
    echo "FAIL: .tflint.hcl not found (no lint rules configured)" && exit 1
  fi
  echo "Running tflint (AWS plugin)..."
  tflint --init
  # Lint only modules/ (exclude global/ convention file and upstream examples)
  for dir in modules/*/; do
    [ -f "$dir/main.tf" ] || continue
    echo "  Linting $dir..."
    tflint --chdir="$dir" --format json >> "$EVIDENCE_DIR/security-scans/tflint-$(date -u +%Y%m%dT%H%M%SZ).json" 2>&1 \
      || { echo "  tflint found issues in $dir (see evidence)"; LINT_PASS=false; }
    tflint --chdir="$dir" || LINT_PASS=false
  done
else
  echo "FAIL: tflint not installed (required for lint gate)" && exit 1
fi

# checkov: security scanning (scope to MODULE_DIR when set)
if command -v checkov >/dev/null 2>&1; then
  CHECKOV_DIR="${MODULE_DIR:-modules/}"
  CHECKOV_ARGS="-d $CHECKOV_DIR --framework terraform --quiet"
  # Use module-specific .checkov.yml if it exists
  if [ -f "$CHECKOV_DIR/.checkov.yml" ]; then
    CHECKOV_ARGS="$CHECKOV_ARGS --config-file $CHECKOV_DIR/.checkov.yml"
  fi
  # Use custom checks if directory exists
  if [ -d ".checkov/custom_checks/" ]; then
    CHECKOV_ARGS="$CHECKOV_ARGS --external-checks-dir .checkov/custom_checks/"
  fi
  echo "Running checkov security scan on ${CHECKOV_DIR}..."
  checkov $CHECKOV_ARGS || LINT_PASS=false
else
  echo "FAIL: checkov not installed (required for security scan)" && exit 1
fi

if [ "$LINT_PASS" = "true" ]; then
  echo "PASSED: build:lint"
else
  echo "FAIL: build:lint" && exit 1
fi
