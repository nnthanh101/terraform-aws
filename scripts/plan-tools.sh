#!/bin/bash
set -euo pipefail

# Verify tools available in devcontainer image
ver() {
  case "$1" in
    go)      go version 2>&1 ;;
    kubectl) kubectl version --client 2>&1 ;;
    helm)    helm version --short 2>&1 ;;
    *)       "$1" --version 2>&1 ;;
  esac | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

PASS=0; FAIL=0
TOOLS="terraform terragrunt tflint checkov trivy infracost aws az go task starship git node npm cdk kubectl helm k3d act"

for tool in $TOOLS; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf "  %-14s %s\n" "$tool" "$(ver "$tool")"
    PASS=$((PASS+1))
  else
    printf "  %-14s %s\n" "$tool" "MISSING"
    FAIL=$((FAIL+1))
  fi
done

echo ""
TOTAL=$(echo $TOOLS | wc -w | tr -d ' ')
echo "Tools: $PASS present, $FAIL missing (of $TOTAL)"
[ $FAIL -eq 0 ] || exit 1
