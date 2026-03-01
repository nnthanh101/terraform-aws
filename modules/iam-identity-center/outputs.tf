# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-ia/terraform-aws-iam-identity-center v1.0.4 (Apache-2.0). See NOTICE.

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
