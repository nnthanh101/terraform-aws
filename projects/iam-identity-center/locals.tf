# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

data "aws_caller_identity" "current" {}

locals {
  management_account_id = coalesce(var.account_id, data.aws_caller_identity.current.account_id)

  landing_zone_accounts = compact([
    local.management_account_id,
    var.security_account_id,
    var.workload_account_id,
  ])
}
