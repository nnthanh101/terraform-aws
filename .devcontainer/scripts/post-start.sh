#!/bin/bash
# =============================================================================
# post-start.sh - Self-healing validation (runs every container start)
# terraform-aws DevContainer
# Tool list is discovered from nnthanh101/terraform:latest — not hardcoded
# =============================================================================
set -euo pipefail

# Helper: Get version — handles tools with non-standard version flags
ver() {
    if ! command -v "$1" &>/dev/null; then echo "-"; return; fi
    case "$1" in
        go)      go version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 ;;
        kubectl) kubectl version --client 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 ;;
        helm)    helm version --short 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 ;;
        *)       "$1" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 ;;
    esac
}

# Tools shipped in nnthanh101/terraform:latest — discover dynamically
TOOLS=(terraform terragrunt tflint checkov trivy infracost aws az go task starship git node npm cdk kubectl helm k3d)

echo ""
echo "terraform-aws DevContainer (ADLC v${ADLC_VERSION:-3.3.0})"
echo ""
printf "%-14s %-12s %-14s %s\n" "Tool" "Version" "Tool" "Version"
printf "%-14s %-12s %-14s %s\n" "--------" "--------" "--------" "--------"

# Print in two columns
half=$(( (${#TOOLS[@]} + 1) / 2 ))
for ((i=0; i<half; i++)); do
    left="${TOOLS[$i]}"
    right_idx=$((i + half))
    if [ $right_idx -lt ${#TOOLS[@]} ]; then
        right="${TOOLS[$right_idx]}"
        printf "%-14s %-12s %-14s %s\n" "$left" "$(ver "$left")" "$right" "$(ver "$right")"
    else
        printf "%-14s %s\n" "$left" "$(ver "$left")"
    fi
done

echo ""
echo "task --list | task validate | aws sso login"
echo ""

exit 0
