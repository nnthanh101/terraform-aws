#!/bin/bash
set -euo pipefail

# tflint + checkov CI-aware linting
LINT_PASS=true

if command -v tflint >/dev/null 2>&1; then
  tflint --recursive
else
  if [ -n "${CI:-}" ]; then echo "FAIL: tflint not installed in CI" && exit 1; fi
  echo "WARN: tflint not installed (install for full lint coverage)"
fi

if command -v checkov >/dev/null 2>&1; then
  checkov -d modules/ --framework terraform --quiet || LINT_PASS=false
else
  if [ -n "${CI:-}" ]; then echo "FAIL: checkov not installed in CI" && exit 1; fi
  echo "WARN: checkov not installed (install for security scanning)"
fi

if [ "$LINT_PASS" = "true" ]; then
  echo "PASSED: build:lint"
else
  echo "FAIL: build:lint" && exit 1
fi
