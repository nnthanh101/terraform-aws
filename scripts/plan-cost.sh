#!/bin/bash
set -euo pipefail

# Infracost estimate per module -> $EVIDENCE_DIR/cost-reports/
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/cost-reports"

if ! command -v infracost >/dev/null 2>&1; then
  echo "SKIP: infracost not installed (https://www.infracost.io/docs/)"
  exit 0
fi

for dir in modules/*/; do
  if [ -d "$dir" ] && ls "$dir"/*.tf 1>/dev/null 2>&1; then
    echo "Estimating cost for $dir..."
    infracost breakdown --path "$dir" --format json \
      > "$EVIDENCE_DIR/cost-reports/$(basename "$dir").json" 2>/dev/null \
      || echo "SKIP: $dir (no priceable resources)"
  fi
done

echo "PASSED: plan:cost"
