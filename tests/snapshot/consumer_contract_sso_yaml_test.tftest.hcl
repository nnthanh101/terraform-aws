# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier-1 snapshot test — consumer contract: SSO module with YAML config_path input.
#
# ADR-008: Auditor-Friendly YAML API.
# The existing identity_center_test.tftest.hcl uses HCL variable inputs exclusively.
# This test ADDS YAML-path coverage that the existing test does NOT exercise:
#   - config_path set to a real YAML fixture directory
#   - permission_sets and account_assignments loaded from YAML files
#   - assert that the module reads YAML and materialises expected keys
#
# TF 1.11 run-block module{} syntax: when source = modules/sso (the module itself),
# outputs are accessible directly at the root scope, not via module.<alias>.
# override_data targets data.<type>.<name> (root scope, no module prefix).
#
# mock_provider + override_data: zero cost, zero credentials, 2-3 second runtime.
# All assertions target PLANNED computed values (no test-injected mock constants).

mock_provider "aws" {}

# ---------------------------------------------------------------------------
# Test 1: YAML config is parsed — permission set keys appear in planned outputs
# ---------------------------------------------------------------------------
run "yaml_permission_sets_parsed" {
  command = plan

  # Point this run directly at the sso module (it becomes the root for this run).
  module {
    source = "../../modules/sso"
  }

  # Override SSO instance data source for this run (root-scope, no module prefix).
  override_data {
    target = data.aws_ssoadmin_instances.sso_instance
    values = {
      arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
      identity_store_ids = ["d-mock12345678"]
    }
  }

  variables {
    # YAML path — resolved relative to the test configuration root (tests/snapshot/).
    config_path = "fixtures/sso-yaml"

    enable_organizations_lookup = false

    default_tags = {
      CostCenter         = "platform"
      Project            = "sso"
      Environment        = "test"
      DataClassification = "internal"
    }

    # Minimal SSO groups so the module can plan principals.
    sso_groups = {
      PlatformTeam = { group_name = "PlatformTeam" }
      AuditTeam    = { group_name = "AuditTeam" }
    }
  }

  # The YAML fixture defines PlatformAdmin and AuditReadOnly permission sets.
  # If YAML was NOT read, effective_permission_sets would be empty (no HCL var.permission_sets).
  # Asserting on the count proves the module executed the yamldecode() + merge() path.
  assert {
    condition     = length(permission_set_arns) == 2
    error_message = "Expected 2 permission sets from YAML fixture (PlatformAdmin + AuditReadOnly); YAML config_path read failed"
  }
}

# ---------------------------------------------------------------------------
# Test 2: YAML-defined permission set keys are correct (PascalCase — ADR-011)
# ---------------------------------------------------------------------------
run "yaml_permission_set_keys_correct" {
  command = plan

  module {
    source = "../../modules/sso"
  }

  override_data {
    target = data.aws_ssoadmin_instances.sso_instance
    values = {
      arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
      identity_store_ids = ["d-mock12345678"]
    }
  }

  variables {
    config_path = "fixtures/sso-yaml"

    enable_organizations_lookup = false

    default_tags = {
      CostCenter         = "platform"
      Project            = "sso"
      Environment        = "test"
      DataClassification = "internal"
    }

    sso_groups = {
      PlatformTeam = { group_name = "PlatformTeam" }
      AuditTeam    = { group_name = "AuditTeam" }
    }
  }

  # Specific key assertions lock the YAML key contract: rename in YAML = test failure.
  assert {
    condition     = contains(keys(permission_set_arns), "PlatformAdmin")
    error_message = "permission_set_arns must contain 'PlatformAdmin' key from YAML fixture"
  }

  assert {
    condition     = contains(keys(permission_set_arns), "AuditReadOnly")
    error_message = "permission_set_arns must contain 'AuditReadOnly' key from YAML fixture"
  }
}

# ---------------------------------------------------------------------------
# Test 3: config_path output reflects the input path (APRA CPS 234 audit trail)
# ---------------------------------------------------------------------------
run "yaml_config_path_output_set" {
  command = plan

  module {
    source = "../../modules/sso"
  }

  override_data {
    target = data.aws_ssoadmin_instances.sso_instance
    values = {
      arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
      identity_store_ids = ["d-mock12345678"]
    }
  }

  variables {
    config_path = "fixtures/sso-yaml"

    enable_organizations_lookup = false

    default_tags = {
      CostCenter         = "platform"
      Project            = "sso"
      Environment        = "test"
      DataClassification = "internal"
    }

    sso_groups = {
      PlatformTeam = { group_name = "PlatformTeam" }
      AuditTeam    = { group_name = "AuditTeam" }
    }
  }

  # config_path output = non-null proves the audit-trail output is wired correctly.
  assert {
    condition     = config_path != null
    error_message = "config_path output must be non-null when config_path input is set (APRA CPS 234 audit trail)"
  }

  assert {
    condition     = strcontains(config_path, "fixtures")
    error_message = "config_path output must reference the fixture path passed in"
  }
}
