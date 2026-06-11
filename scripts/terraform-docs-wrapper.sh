#!/usr/bin/env bash
# Container-first wrapper for terraform-docs
# Uses nnthanh101/terraform:latest which includes terraform-docs v0.19.0
# Falls back to local binary if available (e.g., inside DevContainer)
set -euo pipefail

if command -v terraform-docs &>/dev/null; then
  exec terraform-docs "$@"
else
  exec docker run --rm -v "$(git rev-parse --show-toplevel):/workspace" -w /workspace \
    nnthanh101/terraform:latest terraform-docs "$@"
fi
