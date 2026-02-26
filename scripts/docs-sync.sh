#!/bin/bash
set -euo pipefail

# Sync docs/ into DevOps-TechDocs submodule (docs/site/docs/terraform-aws/)
# Prerequisites: git submodule add https://github.com/1xOps/DevOps-TechDocs.git docs/site

SITE_DIR="docs/site"
TARGET_DIR="$SITE_DIR/docs/terraform-aws"

if [ ! -d "$SITE_DIR" ]; then
  echo "SKIP: DevOps-TechDocs submodule not found at $SITE_DIR"
  echo "  Run: git submodule add https://github.com/1xOps/DevOps-TechDocs.git docs/site"
  exit 0
fi

echo "=== Docs Sync ==="
mkdir -p "$TARGET_DIR"

# Sync module docs
for doc in docs/*.mdx docs/*.md; do
  [ -f "$doc" ] || continue
  cp "$doc" "$TARGET_DIR/"
  echo "  Synced: $doc -> $TARGET_DIR/"
done

# Sync ADR docs
if [ -d docs/adr ]; then
  mkdir -p "$TARGET_DIR/adr"
  cp docs/adr/*.md docs/adr/*.mdx "$TARGET_DIR/adr/" 2>/dev/null || true
  echo "  Synced: docs/adr/ -> $TARGET_DIR/adr/"
fi

# Sync module READMEs
for mod in modules/*/; do
  [ -f "$mod/README.md" ] || continue
  MOD_NAME=$(basename "$mod")
  cp "$mod/README.md" "$TARGET_DIR/$MOD_NAME.md"
  echo "  Synced: $mod/README.md -> $TARGET_DIR/$MOD_NAME.md"
done

echo "PASSED: docs:sync"
