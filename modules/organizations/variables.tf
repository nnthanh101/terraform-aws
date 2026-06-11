# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.

# ---------------------------------------------------------------------------
# Organization (adopt-existing vs create)
# ---------------------------------------------------------------------------

variable "create_organization" {
  description = "When false (default), adopt an existing AWS Organization via data source. When true, create a new organization — only valid for a brand-new AWS account with no existing org."
  type        = bool
  default     = false
}

variable "organization_feature_set" {
  description = "Feature set for a newly created organization. Ignored when create_organization = false. Valid values: ALL, CONSOLIDATED_BILLING."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.organization_feature_set)
    error_message = "organization_feature_set must be ALL or CONSOLIDATED_BILLING."
  }
}

variable "organization_enabled_policy_types" {
  description = "Policy types to enable on the organization. Ignored when create_organization = false."
  type        = list(string)
  default     = ["TAG_POLICY", "SERVICE_CONTROL_POLICY"]

  validation {
    condition = alltrue([
      for pt in var.organization_enabled_policy_types :
      contains(["SERVICE_CONTROL_POLICY", "TAG_POLICY", "BACKUP_POLICY", "CHATBOT_POLICY", "AISERVICES_OPT_OUT_POLICY", "DECLARATIVE_POLICY_EC2", "INSPECTOR_POLICY"], pt)
    ])
    error_message = "Each item in organization_enabled_policy_types must be a valid AWS Organizations policy type."
  }
}

variable "organization_aws_service_access_principals" {
  description = "AWS service principals to enable for Organizations integration. Ignored when create_organization = false."
  type        = list(string)
  default = [
    "account.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "compute-optimizer.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "guardduty.amazonaws.com",
    "health.amazonaws.com",
    "iam.amazonaws.com",
    "ram.amazonaws.com",
    "resource-explorer-2.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
    "tagpolicies.tag.amazonaws.com",
  ]
}

# ---------------------------------------------------------------------------
# Organizational Units
# ---------------------------------------------------------------------------

variable "organizational_units" {
  description = <<-EOT
    Map of OU name → { parent } where parent is either "ROOT" (attaches to the org root)
    or the name of another OU in this map. Nesting is resolved by topological sort within
    locals.tf. Example:

      organizational_units = {
        Security       = { parent = "ROOT" }
        Infrastructure = { parent = "ROOT" }
        Workloads      = { parent = "ROOT" }
        Prod           = { parent = "Workloads" }
        NonProd        = { parent = "Workloads" }
        Sandbox        = { parent = "ROOT" }
      }
  EOT
  type = map(object({
    parent = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Account vending
# ---------------------------------------------------------------------------

variable "accounts" {
  description = <<-EOT
    Map of logical key → account spec. Each account is provisioned via
    aws_organizations_account. Account creation is IRREVERSIBLE once the account
    is bootstrapped — terraform apply MUST be reviewed by a human (HITL) before
    execution. Caller-supplied email addresses must be unique across all AWS accounts.

    Example:
      accounts = {
        sandbox-workload = {
          name  = "my-sandbox"
          email = "aws+sandbox@example.com"
          ou    = "Sandbox"
          tags  = { CostCenter = "platform", Owner = "platform-team" }
        }
      }
  EOT
  type = map(object({
    name  = string
    email = string
    ou    = string
    tags  = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.accounts : length(v.name) >= 1 && length(v.name) <= 50])
    error_message = "Account name must be between 1 and 50 characters."
  }

  validation {
    condition     = alltrue([for k, v in var.accounts : can(regex("^[^@]+@[^@]+$", v.email))])
    error_message = "Each account.email must be a valid email address."
  }
}

# ---------------------------------------------------------------------------
# Tag Policy
# ---------------------------------------------------------------------------

variable "tag_policy" {
  description = <<-EOT
    Configuration for the TAG_POLICY attached to the organization root.
    Set enabled = false to skip tag policy creation entirely.

    - mandatory_keys: keys that must be present on all resources
    - environment_allowed_values: permitted values for the Environment tag
    - target_ous: list of OU names to attach the policy to. Empty list = attach to org root.
  EOT
  type = object({
    enabled = optional(bool, true)
    mandatory_keys = optional(list(string), [
      "CostCenter", "Owner", "Environment", "ManagedBy"
    ])
    environment_allowed_values = optional(list(string), [
      "sandbox", "dev", "test", "sit", "uat", "preprod", "prod", "dr"
    ])
    target_ous = optional(list(string), [])
  })
  default = {}
}

# ---------------------------------------------------------------------------
# Service Control Policies
# ---------------------------------------------------------------------------

variable "baseline_scps" {
  description = <<-EOT
    When true, attach a minimal baseline SCP set to the organization root:
      1. deny-leave-organization   — prevents member accounts from leaving the org
      2. deny-root-user-actions    — blocks interactive root user API calls
      3. require-mandatory-tags    — denies resource creation without mandatory tag keys

    The require-mandatory-tags SCP enforces the same keys as tag_policy.mandatory_keys.
  EOT
  type        = bool
  default     = false
}

variable "service_control_policies" {
  description = <<-EOT
    Optional list of additional SCPs to create and attach to named OUs.
    Each item: { name, description, policy_json, target_ou }
    target_ou must match a key in var.organizational_units or "ROOT".

    Example:
      service_control_policies = [
        {
          name        = "deny-s3-public-access"
          description = "Prevents public S3 ACLs"
          policy_json = jsonencode({ ... })
          target_ou   = "Workloads"
        }
      ]
  EOT
  type = list(object({
    name        = string
    description = optional(string, "")
    policy_json = string
    target_ou   = string
  }))
  default = []

  validation {
    condition     = alltrue([for scp in var.service_control_policies : length(scp.name) >= 1 && length(scp.name) <= 128])
    error_message = "SCP name must be between 1 and 128 characters."
  }
}

# ---------------------------------------------------------------------------
# Delegated administrators
# ---------------------------------------------------------------------------

variable "delegated_administrators" {
  description = <<-EOT
    Map of logical key → { account_key, service_principal } to register delegated
    administrators for AWS services. account_key must match a key in var.accounts.

    Example:
      delegated_administrators = {
        guardduty-delegated = {
          account_key       = "security-tooling"
          service_principal = "guardduty.amazonaws.com"
        }
      }
  EOT
  type = map(object({
    account_key       = string
    service_principal = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Tagging
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to all module-owned resources. Required keys when non-empty: CostCenter, Owner, Environment, ManagedBy."
  type        = map(string)
  default     = {}

  validation {
    condition = length(var.tags) == 0 || alltrue([
      contains(keys(var.tags), "CostCenter"),
      contains(keys(var.tags), "Owner"),
      contains(keys(var.tags), "Environment"),
      contains(keys(var.tags), "ManagedBy"),
    ])
    error_message = "When tags is non-empty it must include: CostCenter, Owner, Environment, ManagedBy."
  }
}
