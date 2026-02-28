# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Root wrapper outputs — re-export from modules/iam-identity-center (ADR-007)

output "account_assignment_data" {
  value       = module.iam_identity_center.account_assignment_data
  description = "Tuple containing account assignment data"
}

output "principals_and_assignments" {
  value       = module.iam_identity_center.principals_and_assignments
  description = "Map containing account assignment data"
}

output "sso_groups_ids" {
  value       = module.iam_identity_center.sso_groups_ids
  description = "A map of SSO groups ids created by this module"
}

output "sso_applications_arns" {
  value       = module.iam_identity_center.sso_applications_arns
  description = "A map of SSO Applications ARNs created by this module"
}

output "sso_applications_group_assignments" {
  value       = module.iam_identity_center.sso_applications_group_assignments
  description = "A map of SSO Applications assignments with groups created by this module"
}

output "sso_applications_user_assignments" {
  value       = module.iam_identity_center.sso_applications_user_assignments
  description = "A map of SSO Applications assignments with users created by this module"
}

output "sso_users_ids" {
  value       = module.iam_identity_center.sso_users_ids
  description = "A map of SSO user IDs created by this module"
}

output "permission_set_arns" {
  value       = module.iam_identity_center.permission_set_arns
  description = "A map of permission set name to ARN"
}

output "sso_instance_arn" {
  value       = module.iam_identity_center.sso_instance_arn
  description = "The ARN of the SSO instance"
}

output "identity_store_id" {
  value       = module.iam_identity_center.identity_store_id
  description = "The ID of the Identity Store"
}

output "config_path" {
  value       = module.iam_identity_center.config_path
  description = "Path to YAML configuration directory for APRA CPS 234 audit trail"
}
