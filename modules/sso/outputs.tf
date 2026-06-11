# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-ia/terraform-aws-sso v1.0.4 (Apache-2.0). See NOTICE.

output "account_assignment_data" {
  value       = local.flatten_account_assignment_data
  description = "Tuple containing account assignment data"

}

output "principals_and_assignments" {
  value       = local.principals_and_their_account_assignments
  description = "Map containing account assignment data"

}

output "sso_groups_ids" {
  value       = { for k, v in aws_identitystore_group.sso_groups : k => v.group_id }
  description = "A map of SSO groups ids created by this module"
}

output "sso_applications_arns" {
  value       = { for k, v in aws_ssoadmin_application.sso_apps : k => v.application_arn }
  description = "A map of SSO Applications ARNs created by this module"
}

output "sso_applications_group_assignments" {
  value       = { for k, v in aws_ssoadmin_application_assignment.sso_apps_groups_assignments : k => v.principal_id }
  description = "A map of SSO Applications assignments with groups created by this module"
}

output "sso_applications_user_assignments" {
  value       = { for k, v in aws_ssoadmin_application_assignment.sso_apps_users_assignments : k => v.principal_id }
  description = "A map of SSO Applications assignments with users created by this module"
}

output "sso_users_ids" {
  value       = { for k, v in aws_identitystore_user.sso_users : k => v.user_id }
  description = "A map of SSO user IDs created by this module"
}

output "permission_set_arns" {
  value       = { for k, v in aws_ssoadmin_permission_set.pset : k => v.arn }
  description = "A map of permission set name to ARN"
}

output "sso_instance_arn" {
  value       = local.ssoadmin_instance_arn
  description = "The ARN of the SSO instance"
}

output "identity_store_id" {
  value       = local.sso_instance_id
  description = "The ID of the Identity Store"
}

output "config_path" {
  value       = var.config_path != "" ? var.config_path : null
  description = "Path to YAML configuration directory for APRA CPS 234 audit trail"
}

output "sso_cli_config" {
  description = "Ready-to-paste ~/.aws/config [sso-session]+[profile] blocks. One [profile] per unique (account_id, permission_set) pair. Pipe to a file or print via: terraform output -raw sso_cli_config"
  value = templatefile("${path.module}/templates/sso-config.tftpl", {
    sso_session_name = var.sso_session_name
    sso_start_url    = var.sso_start_url
    sso_region       = var.sso_region
    # Deduplicate on (account_id, permission_set) — multiple principals may share the
    # same account+pset combination; the CLI profile is per role, not per principal.
    distinct_assignments = values({
      for a in local.flatten_account_assignment_data :
      "${a.account_id}__${a.permission_set}" => {
        account_id     = a.account_id
        permission_set = a.permission_set
      }
    })
  })
}
