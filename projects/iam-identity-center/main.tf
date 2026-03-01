# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# 4-Tier Landing Zone SSO -APRA CPS 234 least privilege
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

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Groups -4-tier Landing Zone separation of duties
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  sso_groups = {
    PlatformTeam = {
      group_name        = "PlatformTeam"
      group_description = "Platform engineering team -break-glass admin access"
    }
    PowerUsers = {
      group_name        = "PowerUsers"
      group_description = "Developers and operators -day-to-day workload access"
    }
    AuditTeam = {
      group_name        = "AuditTeam"
      group_description = "Audit and compliance team -read-only access"
    }
    SecurityTeam = {
      group_name        = "SecurityTeam"
      group_description = "Security operations -SecurityAudit access for incident response"
    }
    AuditTeam = {
      group_name        = "AuditTeam"
      group_description = "Audit and compliance team with read-only access"
    }
  }

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Permission Sets -4-tier with escalating session duration
  #   Tier 1: Admin       (PT1H) -break-glass, time-limited
  #   Tier 2: PowerUser   (PT4H) -day-to-day operations
  #   Tier 3: ReadOnly    (PT8H) -audit, troubleshooting
  #   Tier 4: SecurityAudit (PT8H) -security incident response
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  permission_sets = {
    Admin = {
      description          = "Break-glass administrator - APRA CPS 234 time-limited"
      session_duration     = "PT1H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      tags = {
        ManagedBy          = "Terraform"
        CostCenter         = "platform"
        DataClassification = "confidential"
      }
    }
    PowerUser = {
      description          = "Day-to-day workload operations - no IAM/Org changes"
      session_duration     = "PT4H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/PowerUserAccess"]
      tags = {
        ManagedBy          = "Terraform"
        CostCenter         = "platform"
        DataClassification = "internal"
      }
    }
    ReadOnly = {
      description          = "Read-only access for audit and troubleshooting"
      session_duration     = "PT8H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      tags = {
        ManagedBy          = "Terraform"
        CostCenter         = "platform"
        DataClassification = "internal"
      }
    }
    SecurityAudit = {
      description          = "Security incident response and compliance review"
      session_duration     = "PT8H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/SecurityAudit"]
      tags = {
        ManagedBy          = "Terraform"
        CostCenter         = "security"
        DataClassification = "confidential"
      }
    }
    ReadOnly = {
      description          = "Read-only access across all services"
      session_duration     = "PT8H"
      aws_managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
      tags                 = { ManagedBy = "Terraform" }
    }
  }

  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Account Assignments -group → permission set → account mapping
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  account_assignments = {
    PlatformAdmin = {
      principal_name  = "PlatformTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["Admin"]
      account_ids     = [local.management_account_id]
    }
    PowerUserAccess = {
      principal_name  = "PowerUsers"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["PowerUser"]
      account_ids     = [local.management_account_id]
    }
    AuditReadOnly = {
      principal_name  = "AuditTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["ReadOnly"]
      account_ids     = compact([local.management_account_id, var.security_account_id, var.workload_account_id])
    }
    SecurityOps = {
      principal_name  = "SecurityTeam"
      principal_type  = "GROUP"
      principal_idp   = "INTERNAL"
      permission_sets = ["SecurityAudit"]
      account_ids     = compact([local.management_account_id, var.security_account_id, var.workload_account_id])
    }
  }
}
