# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
#
# AC-3-10 YAML Validation Check-Block Tests
# Tier 1 / Snapshot — command = plan (no AWS credentials required, $0 cost)
#
# Validates that the check blocks added in locals.tf (AC-3-10) surface failures for
# permission_sets values that would arrive via YAML merge and bypass the variables.tf
# validation block. Uses `expect_failures` (Terraform >= 1.8) to assert that specific
# check blocks fire when given invalid input.
#
# Requires: Terraform >= 1.11.0 (see versions.tf)

# ── Test 1: Valid input — no check failures expected ─────────────────────────

run "valid_session_duration_and_tags_pass" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  # create-users-and-groups already has valid permission_sets (PT4H, PT3H) with
  # no per-pset tags map, so both check blocks must pass without failures.
}

# ── Test 2: Invalid session_duration triggers check block ────────────────────

run "invalid_session_duration_fails_check" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  # Override permission_sets with a value whose session_duration is "4 hours" (plain
  # English) — a common YAML authoring mistake that bypasses HCL variable validation.
  variables {
    permission_sets = {
      BadDuration = {
        description      = "Pset with non-ISO-8601 duration from YAML."
        session_duration = "4 hours"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
      }
    }
  }

  expect_failures = [
    check.yaml_session_duration_format,
  ]
}

# ── Test 3: session_duration with minutes suffix passes ──────────────────────

run "valid_session_duration_minutes_passes" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  variables {
    permission_sets = {
      ShortSession = {
        description      = "Pset with a valid PT<n>M session_duration."
        session_duration = "PT30M"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
      }
    }
  }

  # PT30M is valid — no check failures expected.
}

# ── Test 4: session_duration absent — check block must be silent ─────────────

run "absent_session_duration_passes" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  variables {
    permission_sets = {
      NoSession = {
        description = "Pset with no session_duration key — should be accepted."
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
      }
    }
  }

  # No session_duration key → can(v.session_duration) is false → predicate skipped.
}

# ── Test 5: tags map missing CostCenter triggers check block ─────────────────

run "missing_cost_center_tag_fails_check" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  # Clear default_tags so merged result actually lacks CostCenter
  variables {
    default_tags = {}
    permission_sets = {
      MissingCostCenterTag = {
        description      = "Pset missing CostCenter in merged tags — APRA CPS 234 violation."
        session_duration = "PT4H"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
        tags = {
          DataClassification = "internal"
        }
      }
    }
  }

  expect_failures = [
    check.yaml_required_tag_keys,
  ]
}

# ── Test 6: tags map missing DataClassification triggers check block ──────────

run "missing_data_classification_tag_fails_check" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  # Clear default_tags so merged result actually lacks DataClassification
  variables {
    default_tags = {}
    permission_sets = {
      MissingDataClassTag = {
        description      = "Pset missing DataClassification in merged tags — APRA CPS 234 violation."
        session_duration = "PT4H"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
        tags = {
          CostCenter = "platform"
        }
      }
    }
  }

  expect_failures = [
    check.yaml_required_tag_keys,
  ]
}

# ── Test 7: tags map with both required keys passes ───────────────────────────

run "complete_tags_map_passes" {
  command = plan

  module {
    source = "./examples/create-users-and-groups"
  }

  variables {
    permission_sets = {
      FullyTagged = {
        description      = "Pset with all required tag keys present."
        session_duration = "PT4H"
        aws_managed_policies = [
          "arn:aws:iam::aws:policy/ReadOnlyAccess"
        ]
        tags = {
          CostCenter         = "platform"
          DataClassification = "internal"
        }
      }
    }
  }

  # Both required tag keys present — no check failures expected.
}
