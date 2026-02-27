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

# Mock existing SSO group — mock_provider generates random strings which fail UUID validation
override_data {
  target = module.aws-iam-identity-center.data.aws_identitystore_group.existing_sso_groups["AWSControlTowerAdmins"]
  values = {
    group_id = "a0b1c2d3-0001-4000-8000-000000000001"
  }
}

# Mock existing permission set — mock_provider generates random strings which fail ARN validation
override_data {
  target = module.aws-iam-identity-center.data.aws_ssoadmin_permission_set.existing_permission_sets["AWSAdministratorAccess"]
  values = {
    arn = "arn:aws:sso:::permissionSet/ssoins-mock12345678/ps-mock12345678abcd"
  }
}

# Mock the SSM parameter used by locals.tf to resolve account1_account_id
override_data {
  target = data.aws_ssm_parameter.account1_account_id
  values = {
    value = "111111111111"
  }
}

# Mock the AWS IAM policy document data source used for the inline policy
override_data {
  target = data.aws_iam_policy_document.restrictAccessInlinePolicy
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Deny\",\"Action\":\"*\",\"Resource\":\"*\"}]}"
  }
}

run "unit_test" {
  command = plan
  module {
    source = "./examples/inline-policy"
  }

  # Assert: 2 permission sets created (AdministratorAccess with inline policy, ViewOnlyAccess)
  assert {
    condition     = length(module.aws-iam-identity-center.permission_set_arns) == 2
    error_message = "Expected 2 permission set ARNs (AdministratorAccess, ViewOnlyAccess) to be planned"
  }

  # Assert: 2 SSO groups created (Admin, Dev)
  assert {
    condition     = length(module.aws-iam-identity-center.sso_groups_ids) == 2
    error_message = "Expected 2 SSO groups (Admin, Dev) to be planned"
  }
}

run "e2e_test" {
  command = plan
  module {
    source = "./examples/inline-policy"
  }
}
