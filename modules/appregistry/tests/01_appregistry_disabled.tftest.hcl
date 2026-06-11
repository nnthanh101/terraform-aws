# Tier 1 snapshot/plan test — mock_provider, no real AWS credentials required.
# Validates: disabled path creates zero resources; enabled path plans one resource.

mock_provider "aws" {}

run "plan_disabled_returns_empty_tag" {
  command = plan

  variables {
    enable_appregistry = false
    application_name   = "my-platform"
  }

  assert {
    condition     = length(aws_servicecatalogappregistry_application.this) == 0
    error_message = "Expected zero AppRegistry resources when enable_appregistry = false."
  }

  assert {
    condition     = length(output.application_tag) == 0
    error_message = "Expected empty application_tag map when enable_appregistry = false."
  }
}

run "plan_enabled_creates_one_resource" {
  command = plan

  variables {
    enable_appregistry = true
    application_name   = "my-platform"
  }

  assert {
    condition     = length(aws_servicecatalogappregistry_application.this) == 1
    error_message = "Expected one AppRegistry resource when enable_appregistry = true."
  }

  assert {
    condition     = aws_servicecatalogappregistry_application.this[0].name == "my-platform"
    error_message = "Expected application name to equal the input variable."
  }
}
