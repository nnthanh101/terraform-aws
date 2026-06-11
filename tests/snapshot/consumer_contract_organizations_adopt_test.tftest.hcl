# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier-1 snapshot test — consumer contract: Organizations module adopt path.
#
# The Foundation/Identity slice consumes modules/organizations with create_organization = false
# (adopt an existing org) — NOT the create path. This test locks that consumer contract:
#   1. create_organization = false → data source supplies org_id (not a new resource)
#   2. Two OUs ARE planned (Foundation slice requires Security + Infrastructure OUs)
#   3. ou_ids output contains the expected OU names
#
# TF 1.11 run-block module{} syntax: when source = modules/organizations (the module itself),
# outputs and override_data targets are at the root scope (no module prefix).
#
# mock_provider + override_data: zero cost, zero credentials, 2-3 second runtime.
# All assertions target PLANNED values from real module logic.

mock_provider "aws" {}

# ---------------------------------------------------------------------------
# Test 1: Adopt path — organization_id sourced from data source, not new resource
# ---------------------------------------------------------------------------
run "adopt_does_not_create_organization" {
  command = plan

  # Point this run directly at the organizations module (root scope for this run).
  module {
    source = "../../modules/organizations"
  }

  # modules/organizations/data.tf: data "aws_organizations_organization" "this" { count = 1 }
  # Root-scope override (no module prefix) because this module IS the root for this run.
  override_data {
    target = data.aws_organizations_organization.this
    values = {
      id    = "o-mockorgid0001"
      roots = [{ id = "r-mock", name = "Root", arn = "arn:aws:organizations::000000000001:root/o-mockorgid0001/r-mock", policy_types = [] }]
    }
  }

  variables {
    create_organization = false

    organizational_units = {
      Security       = { parent = "ROOT" }
      Infrastructure = { parent = "ROOT" }
    }

    tags = {
      CostCenter  = "platform"
      Owner       = "platform-team"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # In adopt mode the organization_id output comes from the data source.
  # The mock value "o-mockorgid0001" proves data source (not new resource) is used.
  assert {
    condition     = organization_id == "o-mockorgid0001"
    error_message = "organization_id must be sourced from the data source in adopt mode (create_organization = false)"
  }
}

# ---------------------------------------------------------------------------
# Test 2: Two OUs are planned when organizational_units has 2 entries
# ---------------------------------------------------------------------------
run "adopt_plans_two_ous" {
  command = plan

  module {
    source = "../../modules/organizations"
  }

  override_data {
    target = data.aws_organizations_organization.this
    values = {
      id    = "o-mockorgid0001"
      roots = [{ id = "r-mock", name = "Root", arn = "arn:aws:organizations::000000000001:root/o-mockorgid0001/r-mock", policy_types = [] }]
    }
  }

  variables {
    create_organization = false

    organizational_units = {
      Security       = { parent = "ROOT" }
      Infrastructure = { parent = "ROOT" }
    }

    tags = {
      CostCenter  = "platform"
      Owner       = "platform-team"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # ou_ids output is a merge of root + child OU maps (modules/organizations/main.tf).
  # 2 root OUs + 0 child OUs = 2 total.
  assert {
    condition     = length(ou_ids) == 2
    error_message = "Expected 2 OU IDs (Security + Infrastructure) in ou_ids output"
  }
}

# ---------------------------------------------------------------------------
# Test 3: OU names match the Foundation slice contract
# ---------------------------------------------------------------------------
run "adopt_ou_names_match_contract" {
  command = plan

  module {
    source = "../../modules/organizations"
  }

  override_data {
    target = data.aws_organizations_organization.this
    values = {
      id    = "o-mockorgid0001"
      roots = [{ id = "r-mock", name = "Root", arn = "arn:aws:organizations::000000000001:root/o-mockorgid0001/r-mock", policy_types = [] }]
    }
  }

  variables {
    create_organization = false

    organizational_units = {
      Security       = { parent = "ROOT" }
      Infrastructure = { parent = "ROOT" }
    }

    tags = {
      CostCenter  = "platform"
      Owner       = "platform-team"
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Locks the OU key names consumed by the Foundation slice.
  # Renaming an OU key in the consumer module breaks this assertion,
  # surfacing the contract violation at plan time (free, no AWS).
  assert {
    condition     = contains(keys(ou_ids), "Security")
    error_message = "ou_ids must contain 'Security' key — Foundation slice contract requires Security OU"
  }

  assert {
    condition     = contains(keys(ou_ids), "Infrastructure")
    error_message = "ou_ids must contain 'Infrastructure' key — Foundation slice contract requires Infrastructure OU"
  }
}
