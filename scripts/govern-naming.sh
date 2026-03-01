#!/bin/bash
# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# govern-naming.sh — ADR-011 naming convention validation
#
# Validates the 5-layer naming convention stratification defined in:
#   .adlc/projects/terraform-aws/architecture-decisions/ADR-011-naming-convention-stratification.md
#
# Layers validated:
#   Layer 1: Module directories under modules/ — kebab-case, no LZ- prefix
#   Layer 2: HCL variable names in .tf files — snake_case, no lz_ abbreviations
#   Layer 3: Terraform state keys in backend.tf — descriptive path, no lz- prefix
#   Layer 4: SSO group/permission-set names — PascalCase pattern (LZ permitted as bounded qualifier)
#   Layer 5: Tag values in global_variables.tf / locals — full descriptive strings, no LZ* abbreviations
#
# Exit codes:
#   0 — all checks PASS (or only WARNs)
#   1 — one or more checks FAIL
#
# Evidence output: $EVIDENCE_DIR/governance/naming-audit-YYYY-MM-DD.json

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
EVIDENCE_DIR="${EVIDENCE_DIR:-tmp/terraform-aws}"
DATE="$(date -u +%Y-%m-%d)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
AUDIT_FILE="$EVIDENCE_DIR/governance/naming-audit-$DATE.json"
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

mkdir -p "$EVIDENCE_DIR/governance"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
PASS=0
FAIL=0
WARN=0
TOTAL=5

echo ""
echo "=== ADR-011 Naming Convention Audit ==="
echo "Repository root: $REPO_ROOT"
echo "Evidence output: $AUDIT_FILE"
echo ""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pass() {
  echo "CHECK $1/$TOTAL: $2 ... PASS"
  PASS=$((PASS + 1))
}

fail() {
  echo "CHECK $1/$TOTAL: $2 ... FAIL"
  echo "  Violations:"
  echo "$3" | sed 's/^/    /'
  FAIL=$((FAIL + 1))
}

warn() {
  echo "CHECK $1/$TOTAL: $2 ... WARN"
  echo "  $3"
  WARN=$((WARN + 1))
}

# ---------------------------------------------------------------------------
# CHECK 1 — Layer 1: Module + project directories must be kebab-case, no LZ- prefix
#
# ADR-001 + ADR-011 Layer 1: names must match ^[a-z][a-z0-9-]*$ and must not
# start with lz- or lz_ (case-insensitive).
# Scans both modules/ and projects/ directories.
# ---------------------------------------------------------------------------
CHECK_NUM=1
CHECK_NAME="Layer 1 — modules/ + projects/ dirs: kebab-case, no LZ- prefix (ADR-001 + ADR-011)"

L1_VIOLATIONS=""

for parent_dir in "$REPO_ROOT/modules" "$REPO_ROOT/projects"; do
  [ -d "$parent_dir" ] || continue
  parent_name="$(basename "$parent_dir")"
  for dir in "$parent_dir"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    # Must be kebab-case: lowercase letters, digits, hyphens only
    if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]+$'; then
      L1_VIOLATIONS="${L1_VIOLATIONS}  INVALID (not kebab-case): ${parent_name}/${name}\n"
    fi

    # Must not start with lz- (case-insensitive)
    if echo "$name" | grep -qiE '^lz[-_]'; then
      L1_VIOLATIONS="${L1_VIOLATIONS}  LZ-PREFIX DETECTED: ${parent_name}/${name}\n"
    fi
  done
done

if [ -z "$L1_VIOLATIONS" ]; then
  pass "$CHECK_NUM" "$CHECK_NAME"
else
  fail "$CHECK_NUM" "$CHECK_NAME" "$(printf '%b' "$L1_VIOLATIONS")"
fi

# ---------------------------------------------------------------------------
# CHECK 2 — Layer 2: HCL identifiers must be snake_case, no lz_ abbreviations
#
# ADR-011 Layer 2: variable/output/locals declarations in .tf files must match
# ^[a-z][a-z0-9_]*$ and must not start with lz_ (which would be an
# abbreviation — 'landing_zone_...' is the correct full form).
# Scans: modules/, projects/, global/ (including examples/).
# ---------------------------------------------------------------------------
CHECK_NUM=2
CHECK_NAME="Layer 2 — HCL variable names: snake_case, no lz_ abbreviations (ADR-011)"

L2_VIOLATIONS=""

_check_hcl_name() {
  local name="$1" rel_path="$2" kind="$3"

  if ! echo "$name" | grep -qE '^[a-z_][a-z0-9_]*$'; then
    L2_VIOLATIONS="${L2_VIOLATIONS}  NOT snake_case ${kind}: ${name} in ${rel_path}\n"
  fi

  if echo "$name" | grep -qiE '^lz_'; then
    L2_VIOLATIONS="${L2_VIOLATIONS}  LZ-ABBREVIATION ${kind}: ${name} in ${rel_path}\n"
  fi
}

while IFS= read -r -d '' tf_file; do
  rel_path="${tf_file#"$REPO_ROOT/"}"

  # Check variable "name" declarations
  while IFS= read -r var_line; do
    var_name="$(echo "$var_line" | sed -E 's/^[[:space:]]*variable[[:space:]]+"([^"]+)".*/\1/')"
    _check_hcl_name "$var_name" "$rel_path" "variable"
  done < <(grep -E '^[[:space:]]*variable[[:space:]]+"[^"]+"' "$tf_file" 2>/dev/null || true)

  # Check output "name" declarations
  while IFS= read -r out_line; do
    out_name="$(echo "$out_line" | sed -E 's/^[[:space:]]*output[[:space:]]+"([^"]+)".*/\1/')"
    _check_hcl_name "$out_name" "$rel_path" "output"
  done < <(grep -E '^[[:space:]]*output[[:space:]]+"[^"]+"' "$tf_file" 2>/dev/null || true)

done < <(find "$REPO_ROOT/modules" "$REPO_ROOT/projects" "$REPO_ROOT/global" -name "*.tf" -print0 2>/dev/null)

if [ -z "$L2_VIOLATIONS" ]; then
  pass "$CHECK_NUM" "$CHECK_NAME"
else
  fail "$CHECK_NUM" "$CHECK_NAME" "$(printf '%b' "$L2_VIOLATIONS")"
fi

# ---------------------------------------------------------------------------
# CHECK 3 — Layer 3: Terraform state keys in backend.tf must not use lz- prefix
#
# ADR-006 + ADR-011 Layer 3: state keys follow pattern projects/{domain}/terraform.tfstate
# where {domain} is descriptive kebab-case (iam-identity-center, ecs-platform, etc.)
# and must not start with lz-.
# ---------------------------------------------------------------------------
CHECK_NUM=3
CHECK_NAME="Layer 3 — backend.tf state keys: descriptive path, no lz- prefix (ADR-006 + ADR-011)"

L3_VIOLATIONS=""

while IFS= read -r -d '' backend_file; do
  # Extract key = "..." value from backend "s3" blocks
  while IFS= read -r key_line; do
    key_val="$(echo "$key_line" | sed -E 's/^[[:space:]]*key[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"

    if echo "$key_val" | grep -qiE '(^|/)lz[-_]'; then
      rel_path="${backend_file#"$REPO_ROOT/"}"
      L3_VIOLATIONS="${L3_VIOLATIONS}  LZ-PREFIX in state key: ${key_val} (${rel_path})\n"
    fi
  done < <(grep -E '^[[:space:]]*key[[:space:]]*=' "$backend_file" 2>/dev/null || true)
done < <(find "$REPO_ROOT/projects" -name "backend.tf" -print0 2>/dev/null)

# Also check modules/ for any backend blocks (should be none, but validate)
while IFS= read -r -d '' backend_file; do
  while IFS= read -r key_line; do
    key_val="$(echo "$key_line" | sed -E 's/^[[:space:]]*key[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"
    if echo "$key_val" | grep -qiE '(^|/)lz[-_]'; then
      rel_path="${backend_file#"$REPO_ROOT/"}"
      L3_VIOLATIONS="${L3_VIOLATIONS}  LZ-PREFIX in state key: ${key_val} (${rel_path})\n"
    fi
  done < <(grep -E '^[[:space:]]*key[[:space:]]*=' "$backend_file" 2>/dev/null || true)
done < <(find "$REPO_ROOT/modules" -name "backend.tf" -print0 2>/dev/null)

if [ -z "$L3_VIOLATIONS" ]; then
  pass "$CHECK_NUM" "$CHECK_NAME"
else
  fail "$CHECK_NUM" "$CHECK_NAME" "$(printf '%b' "$L3_VIOLATIONS")"
fi

# ---------------------------------------------------------------------------
# CHECK 4 — Layer 5: Tag values must not use LZ* abbreviations
#
# ADR-011 Layer 5: tag values in global_variables.tf (and any locals that set
# tags) must use full descriptive strings. LZ* in tag values creates a parallel
# classification system outside the FOCUS 1.2+ tag taxonomy.
#
# Pattern: look for tag-value strings that start with LZ (case-insensitive)
# inside known tag-definition files.
# ---------------------------------------------------------------------------
CHECK_NUM=4
CHECK_NAME="Layer 5 — tag values: full descriptive strings, no LZ* abbreviations (FOCUS 1.2+)"

L5_VIOLATIONS=""

TAG_FILES=()
# Search for global_variables.tf and any locals.tf that contain tag definitions
while IFS= read -r -d '' f; do
  TAG_FILES+=("$f")
done < <(find "$REPO_ROOT/modules" "$REPO_ROOT/projects" "$REPO_ROOT/global" \
  \( -name "global_variables.tf" -o -name "locals.tf" \) -print0 2>/dev/null | sort -z)

for tag_file in "${TAG_FILES[@]+"${TAG_FILES[@]}"}"; do
  # Find string values that start with LZ (case-insensitive)
  while IFS= read -r line_num_val; do
    rel_path="${tag_file#"$REPO_ROOT/"}"
    L5_VIOLATIONS="${L5_VIOLATIONS}  LZ-ABBREVIATION in tag value: ${rel_path}: ${line_num_val}\n"
  done < <(grep -nE '"[Ll][Zz][A-Za-z0-9_-]' "$tag_file" 2>/dev/null || true)
done

if [ -z "$L5_VIOLATIONS" ]; then
  pass "$CHECK_NUM" "$CHECK_NAME"
else
  fail "$CHECK_NUM" "$CHECK_NAME" "$(printf '%b' "$L5_VIOLATIONS")"
fi

# ---------------------------------------------------------------------------
# CHECK 5 — Layer 4: SSO permission-set names must follow PascalCase pattern
#
# ADR-011 Layer 4: SSO group and permission-set names are the ONE scope where
# LZ is permitted as a bounded qualifier (e.g., LZAdministrators). All such
# names must be PascalCase (no hyphens, no underscores, no lowercase-start).
#
# This check validates that any permission_set_name values in .tf files that
# contain "LZ" conform to PascalCase — detecting the hybrid anti-pattern
# lz-administrators or LZ_ADMINISTRATORS.
# ---------------------------------------------------------------------------
CHECK_NUM=5
CHECK_NAME="Layer 4 — SSO names: PascalCase pattern when LZ qualifier used (ADR-011)"

L4_VIOLATIONS=""

while IFS= read -r -d '' tf_file; do
  # Look for string values containing LZ in permission set / group name contexts
  # Matches: name = "LZ-Something" or "lz_something" — both are violations
  while IFS= read -r match; do
    # Extract the string value
    val="$(echo "$match" | grep -oE '"[^"]*[Ll][Zz][^"]*"' | tr -d '"' | head -1)"
    if [ -z "$val" ]; then continue; fi

    # If it contains LZ, it must be PascalCase: ^LZ[A-Z][a-zA-Z0-9]*$
    # A value like LZAdministrators is PASS; LZ-Administrators or lz_admins is FAIL
    if ! echo "$val" | grep -qE '^LZ[A-Z][a-zA-Z0-9]*$'; then
      rel_path="${tf_file#"$REPO_ROOT/"}"
      L4_VIOLATIONS="${L4_VIOLATIONS}  NOT PascalCase LZ name: ${val} in ${rel_path}\n"
    fi
  done < <(grep -E '"[^"]*[Ll][Zz][^"]*"' "$tf_file" 2>/dev/null || true)
done < <(find "$REPO_ROOT/modules" "$REPO_ROOT/projects" -name "*.tf" -print0 2>/dev/null)

if [ -z "$L4_VIOLATIONS" ]; then
  pass "$CHECK_NUM" "$CHECK_NAME"
else
  fail "$CHECK_NUM" "$CHECK_NAME" "$(printf '%b' "$L4_VIOLATIONS")"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Naming Audit Result: PASS=$PASS  FAIL=$FAIL  WARN=$WARN  (of $TOTAL checks)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---------------------------------------------------------------------------
# Evidence JSON
# ---------------------------------------------------------------------------
cat > "$AUDIT_FILE" <<ENDJSON
{
  "date": "$TIMESTAMP",
  "adr": "ADR-011",
  "script": "scripts/govern-naming.sh",
  "checks": $TOTAL,
  "passed": $PASS,
  "failed": $FAIL,
  "warned": $WARN,
  "status": "$([ $FAIL -eq 0 ] && echo "PASS" || echo "FAIL")",
  "scan_scope": ["modules/", "projects/", "global/", "modules/*/examples/"],
  "lz_policy": {
    "layers_1_2_3_5": "REJECTED — LZ* encodes implementation scaffolding into persistent names",
    "layer_4_sso": "PERMITTED — bounded PascalCase qualifier (LZ[A-Z][a-zA-Z0-9]*) in SSO IdP namespace only",
    "migration_alternative": "Use tag MigrationPhase=landing-zone-onboarding instead of name prefix"
  },
  "layers_validated": [
    "Layer 1: modules/ + projects/ directory names (kebab-case, no LZ- prefix)",
    "Layer 2: HCL identifiers — variables + outputs (snake_case, no lz_ abbreviations)",
    "Layer 3: backend.tf state keys (descriptive path, no lz- prefix)",
    "Layer 4: SSO names (PascalCase when LZ qualifier present — bounded exception)",
    "Layer 5: tag values (full descriptive strings, no LZ* abbreviations)"
  ],
  "evidence_path": "$AUDIT_FILE"
}
ENDJSON

echo ""
echo "Evidence written: $AUDIT_FILE"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "FAILED: govern:naming — $FAIL check(s) failed. See violations above."
  echo "  Reference: .adlc/projects/terraform-aws/architecture-decisions/ADR-011-naming-convention-stratification.md"
  exit 1
fi

echo "PASSED: govern:naming ($PASS/$TOTAL checks passed)"
