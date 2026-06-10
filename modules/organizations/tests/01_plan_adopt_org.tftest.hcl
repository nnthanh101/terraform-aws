# Tier 1 snapshot/plan test — mock_provider, no real AWS credentials required.
# Validates: OU tree planned, accounts planned, tag policy non-empty, baseline SCPs planned.

mock_provider "aws" {}

# Mock the Organizations data source (adopt existing org path, create_organization = false)
override_data {
  target = data.aws_organizations_organization.this[0]
  values = {
    id = "o-mock1234567"
    roots = [{
      id           = "r-mock0001"
      name         = "Root"
      arn          = "arn:aws:organizations::123456789012:root/o-mock1234567/r-mock0001"
      policy_types = []
    }]
    accounts             = []
    non_master_accounts  = []
    master_account_id    = "123456789012"
    master_account_email = "root@example.com"
    master_account_arn   = "arn:aws:organizations::123456789012:account/o-mock1234567/123456789012"
    arn                  = "arn:aws:organizations::123456789012:organization/o-mock1234567"
    feature_set          = "ALL"
  }
}

run "plan_ou_tree" {
  command = plan

  variables {
    create_organization = false

    organizational_units = {
      Security       = { parent = "ROOT" }
      Infrastructure = { parent = "ROOT" }
      Workloads      = { parent = "ROOT" }
      Prod           = { parent = "Workloads" }
      NonProd        = { parent = "Workloads" }
      Sandbox        = { parent = "ROOT" }
    }

    accounts = {
      platform-sandbox = {
        name  = "platform-sandbox"
        email = "aws+platform-sandbox@example.com"
        ou    = "Sandbox"
        tags  = { CostCenter = "platform" }
      }
      dev-workload = {
        name  = "dev-workload"
        email = "aws+dev-workload@example.com"
        ou    = "NonProd"
        tags  = { CostCenter = "engineering" }
      }
    }

    tag_policy = {
      enabled                    = true
      mandatory_keys             = ["CostCenter", "Owner", "Environment", "ManagedBy"]
      environment_allowed_values = ["sandbox", "dev", "test", "uat", "preprod", "prod", "dr"]
      target_ous                 = []
    }

    baseline_scps = true

    tags = {
      CostCenter  = "platform"
      Owner       = "platform-team"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }

  # Assert: root-level OUs are planned (Security, Infrastructure, Workloads, Sandbox = 4)
  assert {
    condition     = length(aws_organizations_organizational_unit.root) == 4
    error_message = "Expected 4 root-level OUs (Security, Infrastructure, Workloads, Sandbox) to be planned."
  }

  # Assert: child OUs are planned (Prod, NonProd = 2)
  assert {
    condition     = length(aws_organizations_organizational_unit.child) == 2
    error_message = "Expected 2 child OUs (Prod, NonProd) to be planned."
  }

  # Assert: accounts are planned (2 accounts)
  assert {
    condition     = length(aws_organizations_account.this) == 2
    error_message = "Expected 2 accounts (platform-sandbox, dev-workload) to be planned."
  }

  # Assert: tag policy is planned (enabled = true)
  assert {
    condition     = length(aws_organizations_policy.tag_policy) == 1
    error_message = "Expected 1 TAG_POLICY to be planned when tag_policy.enabled = true."
  }

  # Assert: tag policy content is non-empty
  assert {
    condition     = length(aws_organizations_policy.tag_policy[0].content) > 10
    error_message = "Tag policy document content must be non-empty JSON."
  }

  # Assert: 3 baseline SCPs planned (deny-leave-org, deny-root-user, require-mandatory-tags)
  assert {
    condition     = length(aws_organizations_policy.baseline) == 3
    error_message = "Expected 3 baseline SCPs when baseline_scps = true."
  }

  # Assert: tag policy attached to org root (no target_ous specified)
  assert {
    condition     = length(aws_organizations_policy_attachment.tag_policy_root) == 1
    error_message = "Expected tag policy to be attached to org root when target_ous is empty."
  }
}

run "plan_no_scps" {
  command = plan

  variables {
    create_organization = false

    organizational_units = {
      Workloads = { parent = "ROOT" }
    }

    baseline_scps = false

    tag_policy = {
      enabled = false
    }

    tags = {}
  }

  # Assert: no baseline SCPs when disabled
  assert {
    condition     = length(aws_organizations_policy.baseline) == 0
    error_message = "Expected 0 baseline SCPs when baseline_scps = false."
  }

  # Assert: no tag policy when disabled
  assert {
    condition     = length(aws_organizations_policy.tag_policy) == 0
    error_message = "Expected 0 tag policies when tag_policy.enabled = false."
  }
}
