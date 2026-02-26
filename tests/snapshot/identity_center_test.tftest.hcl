# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1: Identity Center plan-only tests with mock provider (ADR-004, ADR-008)
# Zero cost, zero credentials — validates custom module HCL + output structure
#
# Strategy: mock_provider + override_data provides synthetic SSO instance values
# enabling full plan validation without real AWS access.

mock_provider "aws" {}

# Override SSO instance data source (returns empty lists by default in mock)
override_data {
  target = module.identity_center.data.aws_ssoadmin_instances.sso_instance
  values = {
    arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
    identity_store_ids = ["d-mock12345678"]
  }
}

# Override organizations data source
override_data {
  target = module.identity_center.data.aws_organizations_organization.organization
  values = {
    accounts = []
  }
}

# Test 1: Plan succeeds with HCL variable inputs
run "plan_succeeds_with_hcl_inputs" {
  command = plan

  assert {
    condition     = length(module.identity_center.sso_groups_ids) == 2
    error_message = "Expected 2 SSO groups (PlatformTeam, AuditTeam)"
  }
}

# Test 2: SSO users are created
run "sso_users_created" {
  command = plan

  assert {
    condition     = length(module.identity_center.sso_users_ids) == 2
    error_message = "Expected 2 SSO users (admin_user, auditor_user)"
  }
}

# Test 3: Permission set ARNs output is NOT empty (Option C core requirement)
run "permission_set_arns_not_empty" {
  command = plan

  assert {
    condition     = length(module.identity_center.permission_set_arns) == 2
    error_message = "Expected 2 permission set ARNs (Admin, ReadOnly) — not empty map"
  }
}

# Test 4: Permission set names match expected keys
run "permission_set_names_correct" {
  command = plan

  assert {
    condition     = contains(keys(module.identity_center.permission_set_arns), "Admin")
    error_message = "permission_set_arns must contain 'Admin' key"
  }

  assert {
    condition     = contains(keys(module.identity_center.permission_set_arns), "ReadOnly")
    error_message = "permission_set_arns must contain 'ReadOnly' key"
  }
}

# Test 5: SSO instance ARN output is populated
run "sso_instance_arn_populated" {
  command = plan

  assert {
    condition     = module.identity_center.sso_instance_arn != ""
    error_message = "sso_instance_arn must be populated from data source"
  }
}

# Test 6: Identity store ID output is populated
run "identity_store_id_populated" {
  command = plan

  assert {
    condition     = module.identity_center.identity_store_id != ""
    error_message = "identity_store_id must be populated from data source"
  }
}

# Test 7: Account assignment data is flattened correctly
run "account_assignments_flattened" {
  command = plan

  # PlatformAdmins: 2 psets × 1 account = 2
  # AuditReadOnly: 1 pset × 2 accounts = 2
  # Total = 4
  assert {
    condition     = length(module.identity_center.account_assignment_data) == 4
    error_message = "Expected 4 flattened account assignments (2+2)"
  }
}

# Test 8: config_path output contains "configs" (APRA CPS 234 audit trail)
run "config_path_contains_configs" {
  command = plan

  assert {
    condition     = strcontains(module.identity_center.config_path, "configs")
    error_message = "config_path must contain 'configs' directory reference"
  }
}
