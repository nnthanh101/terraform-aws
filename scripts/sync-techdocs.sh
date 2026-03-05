#!/bin/bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# sync-techdocs.sh — Generate MDX from module READMEs for DevOps-TechDocs
#
# Usage (local — symlink):
#   bash scripts/sync-techdocs.sh
#   # Writes to /Volumes/Working/projects/DevOps-TechDocs/docs/docs/terraform-aws/modules/auto/
#
# Usage (CI — output to temp dir):
#   bash scripts/sync-techdocs.sh --output /tmp/techdocs-auto
#
# Usage (custom target):
#   TECHDOCS_DIR=/path/to/DevOps-TechDocs bash scripts/sync-techdocs.sh
#
set -euo pipefail

# Parse args
OUTPUT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Determine target directory
if [ -n "$OUTPUT_DIR" ]; then
  # CI mode: write to specified output dir
  TARGET_DIR="$OUTPUT_DIR"
elif [ -n "${TECHDOCS_DIR:-}" ]; then
  TARGET_DIR="${TECHDOCS_DIR}/docs/docs/terraform-aws/modules/auto"
elif [ -d "/Volumes/Working/projects/DevOps-TechDocs" ]; then
  TARGET_DIR="/Volumes/Working/projects/DevOps-TechDocs/docs/docs/terraform-aws/modules/auto"
else
  echo "ERROR: DevOps-TechDocs not found. Set TECHDOCS_DIR or use --output for CI."
  exit 1
fi

mkdir -p "$TARGET_DIR"

# Ensure _category_.json exists (Docusaurus sidebar grouping)
CATEGORY_FILE="${TARGET_DIR}/_category_.json"
if [ ! -f "$CATEGORY_FILE" ]; then
  echo '{"label":"Auto-Generated Reference","position":10}' > "$CATEGORY_FILE"
  echo "Created: _category_.json"
fi

echo "=== Sync TechDocs ==="
echo "Target: ${TARGET_DIR}"
echo ""

SYNCED=0
SKIPPED=0

for MODULE_DIR in modules/*/; do
  MODULE_NAME=$(basename "$MODULE_DIR")

  # Skip modules without .tf files (stubs)
  if ! ls "${MODULE_DIR}"*.tf >/dev/null 2>&1; then
    echo "SKIP: ${MODULE_NAME} (no .tf files)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  README="${MODULE_DIR}README.md"
  if [ ! -f "$README" ]; then
    echo "SKIP: ${MODULE_NAME} (no README.md)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Convert kebab-case to Title Case
  TITLE=$(echo "$MODULE_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

  # Generate MDX with Docusaurus frontmatter
  {
    echo "---"
    echo "id: ${MODULE_NAME}"
    echo "title: \"${TITLE} Terraform Module\""
    echo "sidebar_label: \"${TITLE}\""
    echo "---"
    echo ""
    echo "<!-- Auto-generated from terraform-aws/modules/${MODULE_NAME}/README.md -->"
    echo "<!-- Do not edit manually — changes will be overwritten by sync-techdocs.sh -->"
    echo ""
    cat "$README"
  } > "${TARGET_DIR}/${MODULE_NAME}.mdx"

  echo "OK:   ${MODULE_NAME}.mdx"
  SYNCED=$((SYNCED + 1))
done

echo ""
echo "Result: synced=${SYNCED} skipped=${SKIPPED}"
