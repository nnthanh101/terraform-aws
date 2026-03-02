# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Test harness for identity-center module (ADR-008: Option C)
# Uses HCL variables (not YAML) for deterministic test assertions

module "identity_center" {
  source = "../../modules/iam-identity-center"

  default_tags = {
    CostCenter         = "platform"
    Project            = "iam-identity-center"
    Environment        = "test"
    ServiceName        = "sso"
    DataClassification = "internal"
  }

  sso_groups = {
    PlatformTeam = {
      group_name        = "PlatformTeam"
      group_description = "Platform engineering team"
    }
    AuditTeam = {
      group_name        = "AuditTeam"
      group_description = "Compliance audit team"
    }
  }

  # NOTE: Upstream module requires map key == user_name (locals.tf:159 collects
  # user.user_name, then main.tf:143 indexes sso_users[user_name]). See .header.md.
  sso_users = {
    admin_user = {
      user_name        = "admin_user"
      given_name       = "Admin"
      family_name      = "User"
      email            = "admin@example.com"
      group_membership = ["PlatformTeam"]
    }
    auditor_user = {
      user_name        = "auditor_user"
      given_name       = "Audit"
      family_name      = "User"
      email            = "auditor@example.com"
      group_membership = ["AuditTeam"]
    }
  }

  permission_sets = {
    Admin = {
      description          = "Full administrator access"
      session_duration     = "PT4H"
      tags                 = {}
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }
    ReadOnly = {
      description          = "Read-only access for auditors"
      session_duration     = "PT8H"
      tags                 = {}
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    }
  }

  account_assignments = {
    PlatformAdmins = {
      principal_name  = "PlatformTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin", "ReadOnly"]
      account_ids     = ["123456789012"]
    }
    AuditReadOnly = {
      principal_name  = "AuditTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = ["123456789012", "234567890123"]
    }
  }
}
