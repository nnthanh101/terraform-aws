# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# 4-Tier Landing Zone SSO - APRA CPS 234 least privilege

# Source Strategy (ADR-026):
#   Production:  GitHub monorepo source (unified version tag)
#   Development: Local source for module iteration only:
#     source = "../../modules/sso"
#   Backup:      Private registry (app.terraform.io/oceansoft/sso/aws)

module "identity_center" {
  source = "github.com/nnthanh101/terraform-aws//modules/sso?ref=v2.0.0"

  providers = {
    aws = aws.identity_center
  }

  enable_organizations_lookup = false

  # YAML config path — permission sets and account assignments in auditor-friendly YAML
  # See config/permission_sets.yaml and config/account_assignments.yaml
  config_path = "${path.module}/config"

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Groups - 4-tier Landing Zone separation of duties (HCL — not YAML-managed)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
