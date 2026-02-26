# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Example: IAM Identity Center with HCL variable inputs
# Registry: oceansoft/iam-identity-center/aws

module "identity_center" {
  source  = "oceansoft/iam-identity-center/aws"
  version = "~> 1.0"

  # For local development, use relative path instead:
  # source = "../../modules/iam-identity-center"

  sso_groups = {
    PlatformTeam = {
      group_name        = "PlatformTeam"
      group_description = "Platform engineering team"
    }
  }

  permission_sets = {
    Admin = {
      description          = "Full administrator access"
      session_duration     = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      tags                 = { ManagedBy = "Terraform" }
    }
  }

  account_assignments = {
    PlatformAdmins = {
      principal_name  = "PlatformTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = ["123456789012"]
    }
  }
}
