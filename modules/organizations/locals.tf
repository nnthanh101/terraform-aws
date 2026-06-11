# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.

locals {
  # ---------------------------------------------------------------------------
  # Organization root id — sourced from data (adopt) or created resource
  # ---------------------------------------------------------------------------
  org_root_id = var.create_organization ? (
    aws_organizations_organization.this[0].roots[0].id
  ) : data.aws_organizations_organization.this[0].roots[0].id

  # ---------------------------------------------------------------------------
  # OU topological sort: resolve "ROOT" → org_root_id, parent names → OU id
  # Terraform evaluates for_each at plan time in dependency order, so we split
  # into two passes:
  #   pass1 = OUs whose parent is ROOT
  #   pass2 = OUs whose parent is a pass1 OU (one level of nesting)
  # This gives a clean 2-level hierarchy matching the standard LZ model.
  # Deeper nesting requires adding pass3 etc — kept simple (KISS).
  # ---------------------------------------------------------------------------
  ous_at_root = {
    for k, v in var.organizational_units : k => v
    if v.parent == "ROOT"
  }

  ous_child = {
    for k, v in var.organizational_units : k => v
    if v.parent != "ROOT"
  }

  # ---------------------------------------------------------------------------
  # Tag policy JSON — rendered from typed inputs, no raw JSON in variables
  # ---------------------------------------------------------------------------
  tag_policy_document = jsonencode({
    tags = merge(
      {
        for key in var.tag_policy.mandatory_keys : key => {
          tag_key = {
            "@@assign" = key
          }
          enforced_for = {
            "@@assign" = ["ec2:instance", "rds:db", "s3:bucket", "lambda:function"]
          }
        }
        if key != "Environment"
      },
      {
        "Environment" = {
          tag_key = {
            "@@assign" = "Environment"
          }
          tag_value = {
            "@@assign" = var.tag_policy.environment_allowed_values
          }
          enforced_for = {
            "@@assign" = ["ec2:instance", "rds:db", "s3:bucket", "lambda:function"]
          }
        }
      }
    )
  })

  # ---------------------------------------------------------------------------
  # Baseline SCP documents
  # ---------------------------------------------------------------------------
  scp_deny_leave_org = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyLeaveOrganization"
      Effect   = "Deny"
      Action   = ["organizations:LeaveOrganization"]
      Resource = "*"
    }]
  })

  scp_deny_root_user = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyRootUserActions"
      Effect   = "Deny"
      Action   = ["*"]
      Resource = "*"
      Condition = {
        StringLike = {
          "aws:PrincipalArn" = ["arn:aws:iam::*:root"]
        }
      }
    }]
  })

  scp_require_mandatory_tags = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "RequireMandatoryTagsOnCreate"
      Effect = "Deny"
      Action = [
        "ec2:RunInstances",
        "rds:CreateDBInstance",
        "lambda:CreateFunction",
        "s3:CreateBucket",
        "ecs:RunTask",
      ]
      Resource = "*"
      Condition = {
        "Null" = {
          for key in var.tag_policy.mandatory_keys : "aws:RequestTag/${key}" => "true"
        }
      }
    }]
  })

  # Assembled baseline SCPs list (created only when baseline_scps = true)
  baseline_scp_definitions = var.baseline_scps ? [
    {
      key         = "deny-leave-organization"
      name        = "deny-leave-organization"
      description = "Prevents member accounts from leaving the organization"
      policy_json = local.scp_deny_leave_org
    },
    {
      key         = "deny-root-user-actions"
      name        = "deny-root-user-actions"
      description = "Blocks interactive root user API calls in member accounts"
      policy_json = local.scp_deny_root_user
    },
    {
      key         = "require-mandatory-tags"
      name        = "require-mandatory-tags"
      description = "Denies resource creation without mandatory tag keys"
      policy_json = local.scp_require_mandatory_tags
    },
  ] : []

  baseline_scp_map = { for scp in local.baseline_scp_definitions : scp.key => scp }

  # Caller-supplied SCPs
  caller_scp_map = { for scp in var.service_control_policies : scp.name => scp }
}
