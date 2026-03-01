# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

output "permission_set_arns" {
  value       = module.identity_center.permission_set_arns
  description = "Map of permission set name to ARN"
}

output "sso_groups_ids" {
  value       = module.identity_center.sso_groups_ids
  description = "Map of SSO group name to group ID"
}

output "sso_instance_arn" {
  value       = module.identity_center.sso_instance_arn
  description = "ARN of the SSO instance"
}

output "identity_store_id" {
  value       = module.identity_center.identity_store_id
  description = "ID of the Identity Store"
}
