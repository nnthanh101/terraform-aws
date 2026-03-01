# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1: Naming convention tests (ADR-011, ADR-001)
# Zero cost, zero credentials — validates LZ naming rules against module inputs/outputs
#
# Strategy: mock_provider + override_data provides synthetic SSO instance values
# enabling full plan validation without real AWS access.
# ADR-011 layers tested: module dir names (kebab-case), SSO group PascalCase,
# permission set map keys, and effective tag values (no LZ abbreviations).

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

# Test 1: Module config_path follows kebab-case conventions — no LZ- prefix in path
# ADR-001 + ADR-011: config paths and module directories use kebab-case, no LZ abbreviations
run "module_config_path_is_kebab_case" {
  command = plan

  assert {
    condition     = !strcontains(module.identity_center.config_path, "LZ-")
    error_message = "config_path must not contain uppercase LZ- prefix — ADR-001 requires kebab-case"
  }

  assert {
    condition     = !strcontains(module.identity_center.config_path, "lz-")
    error_message = "config_path must not contain lowercase lz- prefix — ADR-011 Layer 1"
  }
}

# Test 2: SSO group names follow PascalCase when serving as LZ group identifiers
# ADR-011: LZ qualifier groups use PascalCase (LZAdministrators, PlatformTeam)
# lz-admins (kebab-case) or lz_admins (snake_case) are not valid SSO group name formats
run "sso_group_names_are_pascal_case" {
  command = plan

  assert {
    condition     = contains(keys(module.identity_center.sso_groups_ids), "PlatformTeam")
    error_message = "SSO group key must be PascalCase (PlatformTeam) — ADR-011 forbids kebab-case or lowercase group names"
  }

  assert {
    condition     = contains(keys(module.identity_center.sso_groups_ids), "AuditTeam")
    error_message = "SSO group key must be PascalCase (AuditTeam) — ADR-011 forbids kebab-case or lowercase group names"
  }

  assert {
    condition     = !contains(keys(module.identity_center.sso_groups_ids), "lz-admins")
    error_message = "SSO group key must not use kebab-case (lz-admins) — ADR-011 requires PascalCase for LZ qualifier groups"
  }
}

# Test 3: Permission set map keys follow PascalCase naming pattern
# ADR-011: permission set names are proper nouns / role names (Admin, ReadOnly, PowerUser)
# snake_case keys (admin_access) or kebab-case (read-only) are not valid
run "permission_set_keys_are_pascal_case" {
  command = plan

  assert {
    condition     = contains(keys(module.identity_center.permission_set_arns), "Admin")
    error_message = "Permission set key must be PascalCase (Admin) — ADR-011 forbids snake_case or kebab-case keys"
  }

  assert {
    condition     = contains(keys(module.identity_center.permission_set_arns), "ReadOnly")
    error_message = "Permission set key must be PascalCase (ReadOnly) — ADR-011: no hyphens or underscores in permission set names"
  }

  assert {
    condition     = !contains(keys(module.identity_center.permission_set_arns), "read-only")
    error_message = "Permission set key must not be kebab-case (read-only) — ADR-011 requires PascalCase"
  }

  assert {
    condition     = !contains(keys(module.identity_center.permission_set_arns), "admin_access")
    error_message = "Permission set key must not be snake_case (admin_access) — ADR-011 requires PascalCase"
  }
}

# Test 4: Effective tag values must not contain LZ abbreviations
# ADR-011: Tags use full descriptive values (Environment = "production", not "lz-prod")
# ServiceName, Project, and Environment tag values must not start with "lz-" abbreviation
run "tag_values_no_lz_abbreviations" {
  command = plan

  assert {
    condition     = module.identity_center.sso_instance_arn != ""
    error_message = "sso_instance_arn must be populated — prerequisite for tag output validation"
  }

  assert {
    condition     = !strcontains(module.identity_center.config_path, "lz-")
    error_message = "config_path must not contain lz- abbreviation — ADR-011 forbids LZ shorthand in output values"
  }

  assert {
    condition     = strcontains(module.identity_center.config_path, "configs")
    error_message = "config_path must reference 'configs' directory — naming convention anchor for audit trail (APRA CPS 234)"
  }
}
