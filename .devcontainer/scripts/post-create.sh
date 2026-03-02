#!/bin/bash
# =============================================================================
# post-create.sh - Setup after container creation
# terraform-aws DevContainer
# =============================================================================
set -euo pipefail

echo "post-create: Environment setup..."

# Create ADLC evidence directories
EVIDENCE_BASE="${EVIDENCE_DIR:-/workspace/tmp/terraform-aws}"
mkdir -p "$EVIDENCE_BASE"/{coordination-logs,test-results/{tier1-validate,tier2-localstack,tier3-sandbox},security-scans/{checkov,trivy},cost-reports,terraform-plans,screenshots,legal-audit,evidence} 2>/dev/null
echo "  Evidence directories created"

# Validate ADLC symlinks
for link in .claude .specify; do
    if [ -L "$link" ] && [ -e "$link" ]; then
        echo "  $link symlink OK"
    else
        echo "  WARNING: $link symlink missing or broken"
    fi
done

# Initialize terraform modules (if any exist)
for dir in modules/*/; do
    if [ -f "$dir/main.tf" ]; then
        echo "  terraform init: $dir"
        (cd "$dir" && terraform init -backend=false -input=false 2>/dev/null) || true
    fi
done

echo "post-create complete"
