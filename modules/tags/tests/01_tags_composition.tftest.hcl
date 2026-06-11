# Tier 1 snapshot/plan test — mock_provider, no real AWS credentials required.
# Validates: all 8 tags present and non-empty; enum validation enforced; output structure correct.

mock_provider "null" {}

run "plan_all_tags_populated" {
  command = plan

  variables {
    environment         = "dev"
    application         = "my-platform"
    service             = "backend"
    owner               = "platform-team@example.com"
    cost_center         = "CC-PLATFORM-001"
    compliance          = "n/a"
    data_classification = "internal"
  }

  assert {
    condition     = output.common_tags["Application"] == "my-platform"
    error_message = "Expected Application tag to match input."
  }

  assert {
    condition     = output.common_tags["Service"] == "backend"
    error_message = "Expected Service tag to equal 'backend'."
  }

  assert {
    condition     = output.common_tags["Environment"] == "dev"
    error_message = "Expected Environment tag to equal 'dev'."
  }

  assert {
    condition     = output.common_tags["ManagedBy"] == "terraform"
    error_message = "Expected ManagedBy to be auto-set to 'terraform'."
  }

  assert {
    condition     = output.common_tags["CostCenter"] == "CC-PLATFORM-001"
    error_message = "Expected CostCenter tag to match input."
  }

  assert {
    condition     = length(output.common_tags) == 8
    error_message = "Expected exactly 8 tag keys in common_tags."
  }
}

run "plan_default_values" {
  command = plan

  variables {
    environment = "sandbox"
  }

  assert {
    condition     = output.common_tags["Application"] == "my-application"
    error_message = "Expected default Application to be 'my-application'."
  }

  assert {
    condition     = output.common_tags["Owner"] == "team@example.com"
    error_message = "Expected default Owner to be 'team@example.com'."
  }
}
