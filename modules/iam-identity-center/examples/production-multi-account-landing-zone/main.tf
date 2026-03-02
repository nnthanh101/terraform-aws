# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Production multi-account Landing Zone example
# 4-tier permission hierarchy x 3 accounts x ABAC attributes

module "aws-iam-identity-center" {
  source = "../.."

  default_tags = {
    CostCenter         = "platform"
    Project            = "landing-zone"
    Environment        = "production"
    ServiceName        = "sso"
    DataClassification = "confidential"
  }

  # 4 Landing Zone groups
  sso_groups = {
    LZAdministrators = {
      group_name        = "LZAdministrators"
      group_description = "Landing Zone administrators — full access (break-glass: ADR-020)"
    }
    LZPowerUsers = {
      group_name        = "LZPowerUsers"
      group_description = "Power users — deploy workloads, no IAM/billing"
    }
    LZReadOnly = {
      group_name        = "LZReadOnly"
      group_description = "Read-only access for compliance and audit"
    }
    LZSecurityAudit = {
      group_name        = "LZSecurityAudit"
      group_description = "Security audit — CloudTrail, GuardDuty, Config"
    }
  }

  # 4-tier permission sets
  permission_sets = {
    # checkov:skip=CKV_APRA_002:ADR-020 break-glass pattern
    # checkov:skip=CKV_APRA_005:ADR-020 break-glass; boundary deferred
    LZAdministratorAccess = {
      description          = "Full admin access for Landing Zone management (break-glass only, ADR-020)"
      session_duration     = "PT1H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      tags                 = { ManagedBy = "Terraform", Tier = "admin" }
    }
    LZPowerUserAccess = {
      description          = "Power user access — deploy workloads, no IAM mutation"
      session_duration     = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      tags                 = { ManagedBy = "Terraform", Tier = "power-user" }
    }
    LZReadOnlyAccess = {
      description          = "Read-only access for all accounts"
      session_duration     = "PT8H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      tags                 = { ManagedBy = "Terraform", Tier = "read-only" }
    }
    LZSecurityAuditAccess = {
      description      = "Security audit access — CloudTrail, GuardDuty, Config, SecurityHub"
      session_duration = "PT8H"
      aws_managed_policies = [
        "arn:aws:iam::aws:policy/SecurityAudit",
        "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
      ]
      tags = { ManagedBy = "Terraform", Tier = "security-audit" }
    }
  }

  # 3-account assignments (management, security, workload)
  account_assignments = {
    LZAdmins_Management = {
      principal_name  = "LZAdministrators"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["LZAdministratorAccess"]
      account_ids     = [local.management_account_id]
    }
    LZPowerUsers_Workload = {
      principal_name  = "LZPowerUsers"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["LZPowerUserAccess"]
      account_ids     = [local.workload_account_id]
    }
    LZReadOnly_AllAccounts = {
      principal_name  = "LZReadOnly"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["LZReadOnlyAccess"]
      account_ids = [
        local.management_account_id,
        local.security_account_id,
        local.workload_account_id,
      ]
    }
    LZSecurityAudit_AllAccounts = {
      principal_name  = "LZSecurityAudit"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["LZSecurityAuditAccess"]
      account_ids = [
        local.management_account_id,
        local.security_account_id,
        local.workload_account_id,
      ]
    }
  }

  # ABAC: Environment-scoped access control
  sso_instance_access_control_attributes = [
    {
      attribute_name = "Environment"
      source         = ["$${path:enterprise.Environment}"]
    },
    {
      attribute_name = "CostCenter"
      source         = ["$${path:enterprise.CostCenter}"]
    },
  ]
}
