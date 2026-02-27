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
    accounts = [
      { id = "111111111111", name = "management", status = "ACTIVE", arn = "arn:aws:organizations::111111111111:account/o-mock/111111111111", email = "mgmt@example.com" },
      { id = "222222222222", name = "security", status = "ACTIVE", arn = "arn:aws:organizations::222222222222:account/o-mock/222222222222", email = "sec@example.com" },
      { id = "333333333333", name = "workload", status = "ACTIVE", arn = "arn:aws:organizations::333333333333:account/o-mock/333333333333", email = "wl@example.com" },
    ]
  }
}

# Mock the SSM parameter for management account ID
override_data {
  target = data.aws_ssm_parameter.account1_account_id
  values = {
    value = "111111111111"
  }
}

run "lz_unit_test" {
  command = plan
  module {
    source = "./examples/production-multi-account-landing-zone"
  }

  # Assert: 4 LZ groups created
  assert {
    condition     = length(module.aws-iam-identity-center.sso_groups_ids) == 4
    error_message = "Expected 4 LZ groups (LZAdministrators, LZPowerUsers, LZReadOnly, LZSecurityAudit)"
  }

  # Assert: 4 permission sets created
  assert {
    condition     = length(module.aws-iam-identity-center.permission_set_arns) == 4
    error_message = "Expected 4 permission sets (LZAdministratorAccess, LZPowerUserAccess, LZReadOnlyAccess, LZSecurityAuditAccess)"
  }
}

run "lz_e2e_test" {
  command = plan
  module {
    source = "./examples/production-multi-account-landing-zone"
  }
}
