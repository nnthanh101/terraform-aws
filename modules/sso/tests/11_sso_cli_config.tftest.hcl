# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# Tier 1 test: sso_cli_config output rendering proof.
#
# What this test proves:
#   1. RED-GREEN: the templatefile() in outputs.tf renders a non-empty [sso-session] block
#      and at least one [profile ...] block from a minimal mock account_assignments input.
#   2. The rendered string is computed by real Terraform plan logic — not hand-typed.
#   3. No AWS credentials needed: mock_provider + enable_organizations_lookup=false.
#
# Design rationale:
#   - enable_organizations_lookup=false: avoids organizations data source; account_ids
#     must be 12-digit literals (name resolution is skipped when the map is empty).
#   - No override_data for aws_organizations_organization: data source count=0 when
#     enable_organizations_lookup=false, so no override is needed.
#   - One assignment, one account, one permission set: minimum input to produce one
#     [profile] block while keeping the test maximally simple (Karpathy Rule 2).
#   - sso_session_name="testorg": used in both [sso-session testorg] and the profile
#     name prefix — both assertions verify real template substitution.

mock_provider "aws" {}

# Mock the SSO instance data source — required for all module invocations.
# locals.tf:102 reads arns[0] and identity_store_ids[0]; mock must supply at least one element.
override_data {
  target = data.aws_ssoadmin_instances.sso_instance
  values = {
    arns               = ["arn:aws:sso:::instance/ssoins-mock00000001"]
    identity_store_ids = ["d-mock00000001"]
  }
}

# ─────────────────────────────────────────────────────────
# Run 1 — sso_cli_config renders [sso-session] + [profile]
# ─────────────────────────────────────────────────────────
run "sso_cli_config_renders_session_and_profile" {
  command = plan

  variables {
    # CLI config inputs — the three vars consumed by outputs.tf templatefile()
    sso_start_url    = "https://d-9999999999.awsapps.com/start"
    sso_session_name = "testorg"
    sso_region       = "ap-southeast-2"

    # Disable org lookup: account_ids must be 12-digit literals; no data source mock needed.
    enable_organizations_lookup = false

    # Must define the group referenced in account_assignments (principal_name must exist
    # in aws_identitystore_group.sso_groups, which is keyed by sso_groups var).
    sso_groups = {
      PlatformAdmins = {
        group_name        = "PlatformAdmins"
        group_description = "Platform administrators"
      }
    }

    # Must define the permission set referenced in account_assignments (permission_set
    # name must exist in aws_ssoadmin_permission_set.pset, which is keyed by
    # permission_sets var). Without this the resource lookup fails at plan time.
    permission_sets = {
      AdministratorAccess = {
        description          = "Full AWS access"
        session_duration     = "PT4H"
        aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      }
    }

    # Minimal account_assignments: one group → one account → one permission set.
    # Produces exactly one distinct (account_id, permission_set) entry in
    # local.flatten_account_assignment_data → one [profile] block in the output.
    account_assignments = {
      PlatformAdmins = {
        principal_name  = "PlatformAdmins"
        principal_type  = "GROUP"
        principal_idp   = "INTERNAL"
        permission_sets = ["AdministratorAccess"]
        account_ids     = ["123456789012"]
      }
    }
  }

  # Assert 1: [sso-session testorg] block is present.
  # The session name is substituted by the template at line 8 of sso-config.tftpl.
  assert {
    condition     = can(regex("\\[sso-session testorg\\]", output.sso_cli_config))
    error_message = "sso_cli_config must contain [sso-session testorg] — session block was not rendered"
  }

  # Assert 2: at least one [profile ...] block is present.
  # The profile block is rendered by the %{ for a in distinct_assignments } loop in the template.
  assert {
    condition     = can(regex("\\[profile ", output.sso_cli_config))
    error_message = "sso_cli_config must contain at least one [profile ...] block — profile loop produced no output"
  }

  # Assert 3: the profile name encodes the session name, account ID, and permission set.
  # Template line: [profile ${sso_session_name}-${a.account_id}-${replace(a.permission_set," ","_")}]
  assert {
    condition     = can(regex("\\[profile testorg-123456789012-AdministratorAccess\\]", output.sso_cli_config))
    error_message = "sso_cli_config profile name must be testorg-123456789012-AdministratorAccess — template substitution failed"
  }

  # Assert 4: the sso_start_url is embedded in the session block.
  assert {
    condition     = can(regex("sso_start_url = https://d-9999999999\\.awsapps\\.com/start", output.sso_cli_config))
    error_message = "sso_cli_config must contain sso_start_url — start URL was not substituted"
  }

  # Assert 5: the region is embedded in the session block.
  assert {
    condition     = can(regex("sso_region = ap-southeast-2", output.sso_cli_config))
    error_message = "sso_cli_config must contain sso_region = ap-southeast-2 — region was not substituted"
  }
}

# ─────────────────────────────────────────────────────────
# Run 2 — multi-account: one group assigned to two accounts
#          with the same permission set produces TWO distinct
#          profiles (different account_id keys, no collision).
# ─────────────────────────────────────────────────────────
run "sso_cli_config_multi_account_profiles" {
  command = plan

  variables {
    sso_start_url    = "https://d-9999999999.awsapps.com/start"
    sso_session_name = "testorg"
    sso_region       = "ap-southeast-2"

    enable_organizations_lookup = false

    sso_groups = {
      PlatformAdmins = {
        group_name        = "PlatformAdmins"
        group_description = "Platform administrators"
      }
    }

    permission_sets = {
      AdministratorAccess = {
        description          = "Full AWS access"
        session_duration     = "PT4H"
        aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      }
    }

    # One group assigned to TWO DIFFERENT accounts with the same permission set.
    # Deduplication key: "${a.account_id}__${a.permission_set}" — distinct because account IDs differ.
    # Expected: two [profile] blocks in the rendered output.
    account_assignments = {
      PlatformAdmins = {
        principal_name  = "PlatformAdmins"
        principal_type  = "GROUP"
        principal_idp   = "INTERNAL"
        permission_sets = ["AdministratorAccess"]
        account_ids     = ["111111111111", "222222222222"]
      }
    }
  }

  # Both account profiles must appear in the rendered output.
  assert {
    condition     = can(regex("\\[profile testorg-111111111111-AdministratorAccess\\]", output.sso_cli_config))
    error_message = "sso_cli_config must contain profile for account 111111111111"
  }

  assert {
    condition     = can(regex("\\[profile testorg-222222222222-AdministratorAccess\\]", output.sso_cli_config))
    error_message = "sso_cli_config must contain profile for account 222222222222"
  }
}

# ─────────────────────────────────────────────────────────
# Run 3 — DEF-SSO-001 regression: two DIFFERENT principals
#          (a group AND a user) assigned the SAME permission_set
#          on the SAME account_id must produce exactly ONE
#          [profile] block (not error on duplicate key, not two
#          duplicate profiles).
#
# Defect: the dedup map used `=> a` (no grouping operator), so
# two assignments with the same "${account_id}__${permission_set}"
# key caused Terraform to throw "Duplicate object key" at plan time.
# ─────────────────────────────────────────────────────────
run "sso_cli_config_dedupes_same_account_permset" {
  command = plan

  variables {
    sso_start_url    = "https://d-9999999999.awsapps.com/start"
    sso_session_name = "testorg"
    sso_region       = "ap-southeast-2"

    enable_organizations_lookup = false

    # Two principals that will each receive AdministratorAccess on account 123456789012.
    # The dedup key "${account_id}__${permission_set}" collides for both assignments.
    sso_groups = {
      PlatformAdmins = {
        group_name        = "PlatformAdmins"
        group_description = "Platform administrators"
      }
    }

    sso_users = {
      platform_admin_user = {
        user_name        = "platform-admin"
        given_name       = "Platform"
        family_name      = "Admin"
        display_name     = "Platform Admin"
        email            = "platform-admin@example.com"
        group_membership = []
      }
    }

    permission_sets = {
      AdministratorAccess = {
        description          = "Full AWS access"
        session_duration     = "PT4H"
        aws_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      }
    }

    # Group assignment: PlatformAdmins → AdministratorAccess on 123456789012
    # User assignment:  platform_admin_user → AdministratorAccess on 123456789012
    # Both produce flatten_account_assignment_data entries with:
    #   account_id="123456789012", permission_set="AdministratorAccess"
    # The dedup map key collides → DEF-SSO-001 "Duplicate object key" without the fix.
    account_assignments = {
      PlatformAdmins = {
        principal_name  = "PlatformAdmins"
        principal_type  = "GROUP"
        principal_idp   = "INTERNAL"
        permission_sets = ["AdministratorAccess"]
        account_ids     = ["123456789012"]
      }
      platform_admin_user = {
        principal_name  = "platform_admin_user"
        principal_type  = "USER"
        principal_idp   = "INTERNAL"
        permission_sets = ["AdministratorAccess"]
        account_ids     = ["123456789012"]
      }
    }
  }

  # Exactly ONE [profile testorg-123456789012-AdministratorAccess] must appear.
  # Two would indicate dedup failed (duplicate profile). Zero would indicate
  # a Duplicate object key crash aborted the plan.
  assert {
    condition     = length(regexall("\\[profile testorg-123456789012-AdministratorAccess\\]", output.sso_cli_config)) == 1
    error_message = "dedup failed: expected exactly one [profile testorg-123456789012-AdministratorAccess] for the shared (account_id, permission_set) — duplicate key crash or duplicate profile rendered"
  }
}
