# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Cross-domain composability tests: validate outputs are usable by downstream modules
# Tier 1: Zero cost, zero credentials — uses same mock_provider + override_data pattern

mock_provider "aws" {}

override_data {
  target = module.identity_center.data.aws_ssoadmin_instances.sso_instance
  values = {
    arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
    identity_store_ids = ["d-mock12345678"]
  }
}

override_data {
  target = module.identity_center.data.aws_organizations_organization.organization
  values = {
    accounts = []
  }
}

# Test 1: SSO instance ARN matches ARN pattern (composable for downstream IAM policies)
run "identity_center_outputs_composable" {
  command = plan

  assert {
    condition     = can(regex("^arn:aws:sso:::instance/", module.identity_center.sso_instance_arn))
    error_message = "sso_instance_arn must match ARN pattern for downstream IAM policy references"
  }
}

# Test 2: Permission set ARNs map has expected entries (usable in account assignments)
run "permission_set_arns_usable" {
  command = plan

  assert {
    condition     = length(module.identity_center.permission_set_arns) == 2
    error_message = "permission_set_arns must contain 2 entries (Admin, ReadOnly)"
  }

  assert {
    condition     = contains(keys(module.identity_center.permission_set_arns), "Admin")
    error_message = "permission_set_arns must contain Admin key for downstream assignment"
  }
}

# Test 3: Identity store ID is non-empty (required for cross-module user lookups)
run "identity_store_id_format" {
  command = plan

  assert {
    condition     = length(module.identity_center.identity_store_id) > 0
    error_message = "identity_store_id must be non-empty for cross-module user lookups"
  }
}

# Test 4: All 11 outputs have values with test inputs (integration contract)
run "all_outputs_populated" {
  command = plan

  assert {
    condition     = module.identity_center.sso_instance_arn != ""
    error_message = "sso_instance_arn must be populated"
  }

  assert {
    condition     = module.identity_center.identity_store_id != ""
    error_message = "identity_store_id must be populated"
  }

  assert {
    condition     = length(module.identity_center.sso_groups_ids) > 0
    error_message = "sso_groups_ids must have entries"
  }

  assert {
    condition     = length(module.identity_center.sso_users_ids) > 0
    error_message = "sso_users_ids must have entries"
  }

  assert {
    condition     = length(module.identity_center.permission_set_arns) > 0
    error_message = "permission_set_arns must have entries"
  }

  assert {
    condition     = length(module.identity_center.account_assignment_data) > 0
    error_message = "account_assignment_data must have entries"
  }

  assert {
    condition     = module.identity_center.config_path == null || strcontains(module.identity_center.config_path, "configs")
    error_message = "config_path must be null (HCL-only) or reference configs directory (YAML mode)"
  }
}
