# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.

output "organization_id" {
  description = "The ID of the AWS Organization."
  value = var.create_organization ? (
    aws_organizations_organization.this[0].id
  ) : data.aws_organizations_organization.this[0].id
}

output "organization_root_id" {
  description = "The root ID of the AWS Organization (e.g. r-xxxx)."
  value       = local.org_root_id
}

output "ou_ids" {
  description = "Map of OU name to OU ID for all managed organizational units."
  value = merge(
    { for k, v in aws_organizations_organizational_unit.root : k => v.id },
    { for k, v in aws_organizations_organizational_unit.child : k => v.id },
  )
}

output "account_ids" {
  description = "Map of logical account key to AWS account ID for all vended accounts."
  value       = { for k, v in aws_organizations_account.this : k => v.id }
}

output "tag_policy_id" {
  description = "ID of the TAG_POLICY created by this module. Null when tag_policy.enabled = false."
  value       = var.tag_policy.enabled ? aws_organizations_policy.tag_policy[0].id : null
}

output "baseline_scp_ids" {
  description = "Map of baseline SCP name to policy ID. Empty when baseline_scps = false."
  value       = { for k, v in aws_organizations_policy.baseline : k => v.id }
}

output "caller_scp_ids" {
  description = "Map of caller-supplied SCP name to policy ID."
  value       = { for k, v in aws_organizations_policy.caller : k => v.id }
}

output "scp_ids" {
  description = "Combined map of all SCP name to policy ID (baseline + caller-supplied)."
  value = merge(
    { for k, v in aws_organizations_policy.baseline : k => v.id },
    { for k, v in aws_organizations_policy.caller : k => v.id },
  )
}
