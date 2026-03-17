#!/bin/bash
set -euo pipefail

# setup-symlinks.sh: Local developer convenience — create symlinks to private frameworks
# Purpose: Link terraform-aws to local private frameworks for ADLC governance
# Usage: bash scripts/setup-symlinks.sh
# Exit codes: 0 = success, 1 = local frameworks missing or symlink error, 2 = non-MacPro environment
# Note: These symlinks are LOCAL-ONLY (MacPro /Volumes/Working/projects/*). NOT for CI/CD or public clones.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Setting up local framework symlinks (LOCAL-ONLY for MacPro development) ==="
echo ""

# Detect platform
if [[ ! "$OSTYPE" =~ ^darwin ]]; then
  echo "⚠ WARNING: This script is designed for macOS (Darwin). You are on: $OSTYPE"
  echo "Symlinks to /Volumes/Working/projects/* will not exist on non-MacPro systems."
  echo "Skipping symlink creation."
  exit 2
fi

# Define source paths (LOCAL to MacPro only)
ADLC_FRAMEWORK_LOCAL="/Volumes/Working/projects/adlc-framework"
DEVOPS_DOCS_LOCAL="/Volumes/Working/projects/devops-docs"

# Define destination paths (in repo)
ADLC_LINK="$REPO_ROOT/.adlc"
CLAUDE_LINK="$REPO_ROOT/.claude"
SPECIFY_LINK="$REPO_ROOT/.specify"

# Helper function to create symlink idempotently
create_symlink() {
  local src="$1"  # Full path to source (e.g., /Volumes/Working/projects/adlc-framework)
  local dst="$2"  # Full path to destination (e.g., /Volumes/Working/projects/terraform-aws/.adlc)
  local name="$3" # Display name

  # Check if source exists
  if [ ! -e "$src" ]; then
    echo "✗ SKIP ($name): Source not found: $src"
    return 1
  fi

  # If destination already exists as symlink pointing to correct target
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "✓ $name → $src (already correct)"
    return 0
  fi

  # If destination exists as regular file/directory (not symlink), error out
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "✗ ERROR ($name): Destination exists but is not a symlink to $src"
    echo "  Remove manually: rm -rf '$dst'"
    return 1
  fi

  # Create symlink
  if ln -s "$src" "$dst"; then
    echo "✓ $name → $src (created)"
    return 0
  else
    echo "✗ ERROR ($name): Could not create symlink"
    return 1
  fi
}

# Create all symlinks
SUCCESS=true
create_symlink "$ADLC_FRAMEWORK_LOCAL" "$ADLC_LINK" ".adlc" || SUCCESS=false
create_symlink "$ADLC_FRAMEWORK_LOCAL/.claude" "$CLAUDE_LINK" ".claude (convenience link)" || SUCCESS=false
create_symlink "$ADLC_FRAMEWORK_LOCAL/.specify" "$SPECIFY_LINK" ".specify (convenience link)" || SUCCESS=false

echo ""
if [ "$SUCCESS" = true ]; then
  echo "✓ SUCCESS: Local framework symlinks configured"
  echo ""
  echo "These symlinks are LOCAL-ONLY (MacPro /Volumes/Working/projects/*):"
  echo "  - .adlc → $ADLC_FRAMEWORK_LOCAL"
  echo "  - .claude → convenience link (for local shell aliases)"
  echo "  - .specify → convenience link (for local shell aliases)"
  echo ""
  echo "Symlinks are IGNORED in .gitignore (not committed to git)."
  echo ""
  echo "Next steps:"
  echo "  1. Run: task govern:score  # Validate symlinks (CP-1/2/3 PASS)"
  echo "  2. Use ADLC agents/skills/commands normally from repo root"
  exit 0
else
  echo "✗ FAILED: One or more symlink creation steps failed"
  echo ""
  echo "If you don't have local copies of adlc-framework and devops-docs,"
  echo "you can work without symlinks (CI/CD is not affected)."
  echo "To skip this setup: git clone https://github.com/1xOps/terraform-aws.git (non-recursive)"
  exit 1
fi
