# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

# Multi-account Landing Zone account IDs
# In production, source from AWS SSM Parameter Store or terraform_remote_state
data "aws_ssm_parameter" "account1_account_id" {
  name = "tf-aws-iam-idc-module-testing-account1-account-id"
}

locals {
  # Landing Zone accounts
  management_account_id = nonsensitive(data.aws_ssm_parameter.account1_account_id.value)
  security_account_id   = "222222222222" # Replace with SSM or remote state
  workload_account_id   = "333333333333" # Replace with SSM or remote state
}
