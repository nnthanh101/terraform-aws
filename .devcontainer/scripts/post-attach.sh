#!/bin/bash
# =============================================================================
# post-attach.sh - Runs when VS Code attaches to the container
# terraform-aws DevContainer
# =============================================================================

# Starship cache (BusyBox-safe: no A || B && C precedence issues)
if ! mkdir -p ~/.cache/starship 2>/dev/null; then
    export STARSHIP_CACHE=/tmp/starship-cache
    mkdir -p "$STARSHIP_CACHE"
fi

# Wire STARSHIP prompt if available and not already configured
if command -v starship >/dev/null 2>&1; then
    if ! grep -q 'starship init bash' ~/.bashrc 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
fi

exec bash --login
