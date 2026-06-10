# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.

# Adopt an existing organization (default path — create_organization = false)
data "aws_organizations_organization" "this" {
  count = var.create_organization ? 0 : 1
}
