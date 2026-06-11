# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.

# ---------------------------------------------------------------------------
# Organization (optional creation — most landing zones adopt an existing org)
# ---------------------------------------------------------------------------

resource "aws_organizations_organization" "this" {
  count = var.create_organization ? 1 : 0

  feature_set                   = var.organization_feature_set
  enabled_policy_types          = var.organization_enabled_policy_types
  aws_service_access_principals = var.organization_aws_service_access_principals
}

# ---------------------------------------------------------------------------
# Organizational Units — pass 1: root-level OUs
# ---------------------------------------------------------------------------

resource "aws_organizations_organizational_unit" "root" {
  for_each = local.ous_at_root

  name      = each.key
  parent_id = local.org_root_id

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Organizational Units — pass 2: child OUs (one level below root OUs)
# ---------------------------------------------------------------------------

resource "aws_organizations_organizational_unit" "child" {
  for_each = local.ous_child

  name      = each.key
  parent_id = aws_organizations_organizational_unit.root[each.value.parent].id

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Account vending
# ---------------------------------------------------------------------------

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name  = each.value.name
  email = each.value.email
  parent_id = (
    each.value.ou == "ROOT"
    ? local.org_root_id
    : try(
      aws_organizations_organizational_unit.root[each.value.ou].id,
      aws_organizations_organizational_unit.child[each.value.ou].id,
    )
  )

  # iam_user_access_to_billing defaults to ALLOW; close_on_deletion = false (safe default)
  iam_user_access_to_billing = "ALLOW"

  tags = merge(var.tags, each.value.tags)

  lifecycle {
    # Account closure is destructive and irreversible.
    # Always set close_on_deletion deliberately in the consumer module.
    prevent_destroy = false
    ignore_changes  = [email, name]
  }
}

# ---------------------------------------------------------------------------
# Tag Policy
# ---------------------------------------------------------------------------

resource "aws_organizations_policy" "tag_policy" {
  count = var.tag_policy.enabled ? 1 : 0

  name        = "platform-mandatory-tag-policy"
  description = "Enforces mandatory tag keys and Environment enum on supported resources"
  type        = "TAG_POLICY"
  content     = local.tag_policy_document

  tags = var.tags
}

# Attach tag policy to org root (when no specific OUs are listed)
resource "aws_organizations_policy_attachment" "tag_policy_root" {
  count = (var.tag_policy.enabled && length(var.tag_policy.target_ous) == 0) ? 1 : 0

  policy_id = aws_organizations_policy.tag_policy[0].id
  target_id = local.org_root_id
}

# Attach tag policy to named OUs
resource "aws_organizations_policy_attachment" "tag_policy_ou" {
  for_each = (var.tag_policy.enabled && length(var.tag_policy.target_ous) > 0) ? toset(var.tag_policy.target_ous) : toset([])

  policy_id = aws_organizations_policy.tag_policy[0].id
  target_id = try(
    aws_organizations_organizational_unit.root[each.key].id,
    aws_organizations_organizational_unit.child[each.key].id,
  )
}

# ---------------------------------------------------------------------------
# Baseline SCPs (opt-in via baseline_scps = true)
# ---------------------------------------------------------------------------

resource "aws_organizations_policy" "baseline" {
  for_each = local.baseline_scp_map

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.policy_json

  tags = var.tags
}

resource "aws_organizations_policy_attachment" "baseline" {
  for_each = local.baseline_scp_map

  policy_id = aws_organizations_policy.baseline[each.key].id
  target_id = local.org_root_id
}

# ---------------------------------------------------------------------------
# Caller-supplied SCPs
# ---------------------------------------------------------------------------

resource "aws_organizations_policy" "caller" {
  for_each = local.caller_scp_map

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.policy_json

  tags = var.tags
}

resource "aws_organizations_policy_attachment" "caller" {
  for_each = local.caller_scp_map

  policy_id = aws_organizations_policy.caller[each.key].id
  target_id = (
    each.value.target_ou == "ROOT"
    ? local.org_root_id
    : try(
      aws_organizations_organizational_unit.root[each.value.target_ou].id,
      aws_organizations_organizational_unit.child[each.value.target_ou].id,
    )
  )
}

# ---------------------------------------------------------------------------
# Delegated administrators
# ---------------------------------------------------------------------------

resource "aws_organizations_delegated_administrator" "this" {
  for_each = var.delegated_administrators

  account_id        = aws_organizations_account.this[each.value.account_key].id
  service_principal = each.value.service_principal
}
