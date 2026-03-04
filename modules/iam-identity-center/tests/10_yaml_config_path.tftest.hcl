mock_provider "aws" {}

# Mock SSO instance — required for all module tests
override_data {
  target = module.aws-iam-identity-center.data.aws_ssoadmin_instances.sso_instance
  values = {
    arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
    identity_store_ids = ["d-mock12345678"]
  }
}

# Note: no override_data for data.aws_organizations_organization.organization because
# enable_organizations_lookup = false in the example sets count = 0 on that data source.

run "yaml_config_path_test" {
  command = plan
  module {
    source = "./examples/yaml-config-path"
  }

  # Assert: 3 permission sets from YAML (ReadOnly, SecurityAudit, AdministratorAccess)
  assert {
    condition     = length(module.aws-iam-identity-center.permission_set_arns) == 3
    error_message = "Expected 3 permission sets from YAML config (ReadOnly, SecurityAudit, AdministratorAccess)"
  }
}
