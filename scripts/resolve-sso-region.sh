#!/usr/bin/env bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# resolve-sso-region.sh — Auto-detects the AWS region where IAM Identity Center (SSO) is enabled.
#
# Learned lesson: SSO is NOT always in us-east-1. This script probes the current region first,
# then falls through a list of candidates.
#
# Usage:
#   bash scripts/resolve-sso-region.sh
#
# Output:
#   All status messages go to stderr.
#   Last line on stdout = machine-readable SSO region (e.g. "ap-southeast-2").
#
# HITL requirements:
#   1. IAM Identity Center must already be enabled in AWS Console
#   2. Valid AWS credentials with sso-admin:ListInstances permission

set -euo pipefail

CURRENT_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-southeast-2}}"
CANDIDATE_REGIONS="ap-southeast-2 us-east-1 us-west-2 eu-west-1 eu-central-1 ap-northeast-1"

echo "Probing SSO regions (current: ${CURRENT_REGION})" >&2

# Deduplicate: try current region first, then remaining candidates
SEEN=""
for REGION in $CURRENT_REGION $CANDIDATE_REGIONS; do
  # Skip duplicates
  case " $SEEN " in
    *" $REGION "*) continue ;;
  esac
  SEEN="$SEEN $REGION"

  echo "  Checking ${REGION}..." >&2
  INSTANCE_ARN=$(aws sso-admin list-instances \
    --region "$REGION" \
    --query 'Instances[0].InstanceArn' \
    --output text 2>/dev/null || echo "None")

  if [ "$INSTANCE_ARN" != "None" ] && [ -n "$INSTANCE_ARN" ]; then
    echo "FOUND: SSO instance in ${REGION} (${INSTANCE_ARN})" >&2
    # Last line on stdout = machine-readable region
    echo "$REGION"
    exit 0
  fi
done

echo "ERROR: No SSO instance found in any candidate region" >&2
echo "HINT: Enable IAM Identity Center in AWS Console first, then re-run" >&2
exit 1
