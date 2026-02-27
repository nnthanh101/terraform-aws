mock_provider "aws" {}

# Mock the SSO instance data source inside the module under test
override_data {
  target = module.aws-iam-identity-center.data.aws_ssoadmin_instances.sso_instance
  values = {
    arns               = ["arn:aws:sso:::instance/ssoins-mock12345678"]
    identity_store_ids = ["d-mock12345678"]
  }
}

# Mock the AWS Organizations data source inside the module under test
override_data {
  target = module.aws-iam-identity-center.data.aws_organizations_organization.organization
  values = {
    accounts = []
  }
}

# Mock the SSM parameter used by locals.tf (referenced but unused in this example's main.tf)
override_data {
  target = data.aws_ssm_parameter.account1_account_id
  values = {
    value = "111111111111"
  }
}

run "unit_test" {
  command = plan
  module {
    source = "./examples/instance-access-control-attributes"
  }

  # Assert: SSO instance ARN is populated from the mocked data source
  # Note: This example configures only sso_instance_access_control_attributes (no groups,
  # users, permission sets, or apps). Assertions verify the minimal plan footprint: the
  # SSO instance ARN is wired correctly and no unintended resources are created.
  assert {
    condition     = module.aws-iam-identity-center.sso_instance_arn != ""
    error_message = "sso_instance_arn must be populated from the SSO instance data source"
  }

  # Assert: no permission sets or groups are created (minimal footprint for ABAC config)
  assert {
    condition     = length(module.aws-iam-identity-center.permission_set_arns) == 0
    error_message = "Expected 0 permission sets — instance-access-control-attributes example configures ABAC attributes only"
  }
}

run "e2e_test" {
  command = plan
  module {
    source = "./examples/instance-access-control-attributes"
  }
}