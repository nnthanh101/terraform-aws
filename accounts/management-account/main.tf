# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# 4-Tier Landing Zone SSO — APRA CPS 234 least privilege
#
# Migrated from: projects/sso/main.tf
# ADR-026: GitHub monorepo source (production), local source (development)

data "aws_caller_identity" "current" {}

locals {
  management_account_id = coalesce(var.account_id, data.aws_caller_identity.current.account_id)
}

module "identity_center" {
  # Production: GitHub monorepo source (pinned to latest release)
  # source = "github.com/nnthanh101/terraform-aws//modules/sso?ref=terraform-aws-v2.2.2"
  # Development: local source for module iteration
  source = "../../modules/sso"

  providers = {
    aws = aws.identity_center
  }

  enable_organizations_lookup = false

  # YAML config — permission sets + account assignments in auditor-friendly format
  config_path = "${path.module}/config"

  # Groups — 4-tier Landing Zone separation of duties
  sso_groups = {
    PlatformTeam = {
      group_name        = "PlatformTeam"
      group_description = "Platform engineering team - break-glass admin access"
    }
    PowerUsers = {
      group_name        = "PowerUsers"
      group_description = "Developers and operators - day-to-day workload access"
    }
    AuditTeam = {
      group_name        = "AuditTeam"
      group_description = "Audit and compliance team with read-only access"
    }
    SecurityTeam = {
      group_name        = "SecurityTeam"
      group_description = "Security operations - SecurityAudit access for incident response"
    }
  }
}
