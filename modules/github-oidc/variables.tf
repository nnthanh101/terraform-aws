# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

variable "github_org" {
  description = "GitHub organisation name (e.g. 'nnthanh101' or '1xOps'). Used in the IAM trust-policy sub claim."
  type        = string
}

variable "github_repositories" {
  description = "List of repository names (without org prefix) that are granted trust. Each entry becomes sub claim 'repo:<org>/<repo>:*' for the plan role and 'repo:<org>/<repo>:ref:refs/heads/main' for the apply role."
  type        = list(string)
}

variable "create_oidc_provider" {
  description = "Whether to create the aws_iam_openid_connect_provider for token.actions.githubusercontent.com. Set to false when one already exists in the account (one-per-account constraint)."
  type        = bool
  default     = true
}

variable "plan_role_name" {
  description = "Name of the IAM role assumed by plan/readonly jobs."
  type        = string
  default     = "github-actions-plan"
}

variable "apply_role_name" {
  description = "Name of the IAM role assumed by apply jobs (main-branch-only trust)."
  type        = string
  default     = "github-actions-apply"
}

variable "plan_policy_arns" {
  description = "List of managed policy ARNs to attach to the plan/readonly role. Defaults to ReadOnlyAccess — least-privilege for plan jobs."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

variable "apply_allowed_refs" {
  description = "GitHub sub-claim ref suffixes trusted by the apply role. Defaults to main-branch push. GitHub environment: claims (e.g. 'environment:production') are valid values and preferred for protected deployments that require environment-protection reviewers — they provide an additional human-approval gate beyond branch protection."
  type        = list(string)
  default     = ["ref:refs/heads/main"]

  validation {
    condition     = length(var.apply_allowed_refs) > 0
    error_message = "apply_allowed_refs must contain at least one ref or environment claim."
  }
}

variable "apply_policy_arns" {
  description = "List of managed policy ARNs to attach to the apply role. REQUIRED — no default (caller must supply explicit least-privilege policy ARNs; AdministratorAccess is never assumed)."
  type        = list(string)

  validation {
    condition     = length(var.apply_policy_arns) > 0
    error_message = "apply_policy_arns must contain at least one policy ARN. No default admin policy is set — supply the minimum required permissions for your apply workflow."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds for both roles."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 (1h) and 43200 (12h)."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}
