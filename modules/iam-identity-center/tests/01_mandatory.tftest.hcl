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

# Mock the SSM parameter used by locals.tf to resolve account1_account_id
override_data {
  target = data.aws_ssm_parameter.account1_account_id
  values = {
    value = "111111111111"
  }
}

run "unit_test" {
  command = plan
  module {
    source = "./examples/create-users-and-groups"
  }

  # Assert: 4 SSO groups are created (Admin, Dev, QA, Audit)
  assert {
    condition     = length(module.aws-iam-identity-center.sso_groups_ids) == 4
    error_message = "Expected 4 SSO groups (Admin, Dev, QA, Audit) to be planned"
  }

  # Assert: 2 permission sets are created (AdministratorAccess, ViewOnlyAccess)
  assert {
    condition     = length(module.aws-iam-identity-center.permission_set_arns) == 2
    error_message = "Expected 2 permission set ARNs (AdministratorAccess, ViewOnlyAccess) to be planned"
  }
}

run "e2e_test" {
  command = plan
  module {
    source = "./examples/create-users-and-groups"
  }
}