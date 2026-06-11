# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# GitHub Actions OIDC provider + split-trust IAM roles.
#
# Security boundary:
#   plan role  — sub = repo:<org>/<repo>:*              (any ref, incl. pull_request)
#   apply role — sub = repo:<org>/<repo>:<ref>          (apply_allowed_refs, default: ref:refs/heads/main)
#
# The apply role has NO default managed policy; caller MUST supply apply_policy_arns.

locals {
  # Build the sub-claim condition values for each repository.
  # plan  role: wildcard (any workflow trigger, any ref — read-only is safe)
  # apply role: main-branch-only (narrower trust — write operations must not run on PRs)
  plan_sub_conditions = [
    for repo in var.github_repositories :
    "repo:${var.github_org}/${repo}:*"
  ]

  apply_sub_conditions = [
    for pair in setproduct(var.github_repositories, var.apply_allowed_refs) :
    "repo:${var.github_org}/${pair[0]}:${pair[1]}"
  ]

  # OIDC provider ARN — either created by this module or referenced as existing.
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Fetch current account identity (needed for the oidc_provider_arn when reusing an existing provider).
data "aws_caller_identity" "current" {}

# ── OIDC Provider ──────────────────────────────────────────────────────────────
# One per AWS account. Set create_oidc_provider = false to reuse an existing one.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  # AWS uses sts.amazonaws.com as the audience for OIDC federation.
  client_id_list = ["sts.amazonaws.com"]

  # AWS provider >= 6.x auto-retrieves thumbprints and trusts GitHub OIDC via its bundled CA
  # library — an empty list is correct and sufficient for provider >= 6.x.
  # WARNING: on provider < 6.x an empty list creates an UNTRUSTED provider (all tokens rejected).
  # If you must downgrade below 6.x, add GitHub's current OIDC thumbprint manually:
  #   https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#configuring-the-oidc-trust-with-the-cloud
  thumbprint_list = []

  tags = var.tags
}

# ── IAM Assume-Role Trust Documents ───────────────────────────────────────────

data "aws_iam_policy_document" "plan_trust" {
  statement {
    sid     = "GitHubActionsOIDCPlanTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Wildcard sub — any ref (push, pull_request, workflow_dispatch, etc.)
    # Safe because the plan role is ReadOnly by default.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.plan_sub_conditions
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    sid     = "GitHubActionsOIDCApplyTrust"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Narrow sub — apply_allowed_refs (default: ref:refs/heads/main). Pull requests and other
    # refs not listed in apply_allowed_refs cannot assume this role.
    # This is the split-trust security boundary: apply ≠ plan trust.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.apply_sub_conditions
    }
  }
}

# ── Plan / Readonly Role ───────────────────────────────────────────────────────
# Trusted from any ref (including pull_request). Safe for ReadOnlyAccess.

resource "aws_iam_role" "plan" {
  name                 = var.plan_role_name
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "plan" {
  for_each = toset(var.plan_policy_arns)

  role       = aws_iam_role.plan.name
  policy_arn = each.value
}

# ── Apply Role ─────────────────────────────────────────────────────────────────
# Trusted from refs in apply_allowed_refs (default: ref:refs/heads/main).
# NO default managed policy — caller MUST supply apply_policy_arns.

resource "aws_iam_role" "apply" {
  name                 = var.apply_role_name
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = var.max_session_duration

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "apply" {
  for_each = toset(var.apply_policy_arns)

  role       = aws_iam_role.apply.name
  policy_arn = each.value
}
