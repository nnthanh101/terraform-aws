# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-ia/terraform-aws-iam-identity-center v1.0.4 (Apache-2.0). See NOTICE.
#
# Example: YAML-based configuration using config_path variable.
# This demonstrates the APRA CPS 234 audit-trail-friendly YAML ingestion path.
# YAML files in ./config/ are read and merged with HCL variable values (YAML wins on collision).
#
# Account names work natively when enable_organizations_lookup = true (default).
# The module resolves account names to 12-digit IDs via data.aws_organizations_organization.
# See locals.tf:191-194 in the module source for the account_map implementation.

module "aws-iam-identity-center" {
  source = "../.."

  # Point to the YAML config directory
  config_path = "${path.module}/config"

  # Groups referenced by account_assignments.yaml must be created here
  sso_groups = {
    AuditTeam : {
      group_name        = "AuditTeam"
      group_description = "Security audit team for compliance reviews"
    },
    PlatformTeam : {
      group_name        = "PlatformTeam"
      group_description = "Platform engineering team"
    },
  }

  # FOCUS 1.2+ compliant tags (APRA CPS 234)
  default_tags = {
    CostCenter         = "platform"
    Project            = "iam-identity-center"
    Environment        = "example"
    DataClassification = "internal"
  }

  # When true, account names (e.g., "management") in account_ids resolve to 12-digit IDs
  # via data.aws_organizations_organization. Set false for standalone accounts.
  enable_organizations_lookup = false
}
