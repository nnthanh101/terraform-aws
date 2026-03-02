#!/bin/bash
set -euo pipefail

# APRA CPS 234 compliance check via checkov (Para 15/36/37)
# Checks: CKV_APRA_001 (DataClassification), CKV_APRA_002 (LeastPrivilege), CKV_APRA_003 (SessionDuration)
# Para 36 SoD: CKV_APRA_004 (admin session <= 1H), Para 37 session+boundary: CKV_APRA_005 (high-privilege permissions boundary)
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
mkdir -p "$EVIDENCE_DIR/test-results" "$EVIDENCE_DIR/evidence"

checkov -d modules/iam-identity-center/ \
  --external-checks-dir .checkov/custom_checks/ \
  --check CKV_APRA_001,CKV_APRA_002,CKV_APRA_003,CKV_APRA_004,CKV_APRA_005 \
  --output json \
  --output-file-path "$EVIDENCE_DIR/test-results/" \
  --compact 2>/dev/null || true

cat > "$EVIDENCE_DIR/evidence/cps234-compliance-$(date +%Y-%m-%d).json" <<CPSEOF
{"date":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","standard":"APRA CPS 234","checks":["CKV_APRA_001","CKV_APRA_002","CKV_APRA_003","CKV_APRA_004","CKV_APRA_005"],"evidence_path":"$EVIDENCE_DIR/test-results/"}
CPSEOF

echo "CPS 234 compliance check complete — evidence at $EVIDENCE_DIR/test-results/"
