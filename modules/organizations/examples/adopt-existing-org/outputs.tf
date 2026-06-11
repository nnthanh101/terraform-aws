# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.

output "organization_id" {
  description = "The ID of the AWS Organization adopted by this example."
  value       = module.organizations.organization_id
}

output "organization_root_id" {
  description = "The root ID of the AWS Organization (e.g. r-xxxx)."
  value       = module.organizations.organization_root_id
}

output "ou_ids" {
  description = "Map of OU name to OU ID for all organizational units created by this example."
  value       = module.organizations.ou_ids
}

output "account_ids" {
  description = "Map of logical account key to AWS account ID for all vended accounts. Empty until terraform apply is run."
  value       = module.organizations.account_ids
}

output "tag_policy_id" {
  description = "ID of the TAG_POLICY created by this example."
  value       = module.organizations.tag_policy_id
}

output "baseline_scp_ids" {
  description = "Map of baseline SCP name to policy ID."
  value       = module.organizations.baseline_scp_ids
}
