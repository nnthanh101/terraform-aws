# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Example: IAM Identity Center with HCL variable inputs
# Registry: oceansoft/iam-identity-center/aws

# Source options (select ONE):
# 1. Terraform Registry (after registry-publish):
#    source  = "oceansoft/iam-identity-center/aws"
#    version = "~> 1.1"
# 2. GitHub release:
#    source = "github.com/nnthanh101/terraform-aws//modules/iam-identity-center?ref=iam-identity-center/v1.1.5"
# 3. Local path (monorepo dev):
#    source = "../../modules/iam-identity-center"

module "identity_center" {
  source = "../../modules/iam-identity-center"

  providers = {
    aws = aws.identity_center
  }

  enable_organizations_lookup = false

  sso_groups = {
    PlatformTeam = {
      group_name        = "PlatformTeam"
      group_description = "Platform engineering team"
    }
    AuditTeam = {
      group_name        = "AuditTeam"
      group_description = "Audit and compliance team with read-only access"
    }
  }

  permission_sets = {
    Admin = {
      description          = "Full administrator access"
      session_duration     = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      tags                 = { ManagedBy = "Terraform" }
    }
    ReadOnly = {
      description          = "Read-only access across all services"
      session_duration     = "PT8H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      tags                 = { ManagedBy = "Terraform" }
    }
  }

  account_assignments = {
    PlatformAdmins = {
      principal_name  = "PlatformTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = [local.management_account_id]
    }
    AuditReadOnly = {
      principal_name  = "AuditTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = compact([local.management_account_id, var.security_account_id, var.workload_account_id])
    }
  }
}
