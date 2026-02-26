#!/bin/bash
# =============================================================================
# on-create.sh - One-time container setup (runs only on container creation)
# terraform-aws DevContainer
# Pattern: adlc-framework/.devcontainer/scripts/on-create.sh
# =============================================================================
set -euo pipefail

echo "on-create: One-time setup..."

# Fix machine-id (no sudo needed)
if [ ! -f /etc/machine-id ] || [ ! -s /etc/machine-id ]; then
    cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | head -c 32 > /tmp/machine-id 2>/dev/null || true
    [ -s /tmp/machine-id ] && cat /tmp/machine-id | tee /etc/machine-id >/dev/null 2>&1 || true
    rm -f /tmp/machine-id
fi

# Create cache directories (workspace-local, avoids root-owned volume mounts)
mkdir -p /workspace/.cache/terraform/plugins /workspace/.cache/trivy /workspace/.cache/go/mod 2>/dev/null || true
mkdir -p ~/.cache/starship 2>/dev/null || true

echo "on-create complete"
