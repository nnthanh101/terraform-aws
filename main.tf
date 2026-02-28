# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Root wrapper module call — ADR-007 wrapper pattern for TFC Registry ingestion.
# All business logic lives in modules/iam-identity-center/; this file is pure pass-through.

module "iam_identity_center" {
  source = "./modules/iam-identity-center"

  # Groups
  sso_groups          = var.sso_groups
  existing_sso_groups = var.existing_sso_groups

  # Users
  sso_users                 = var.sso_users
  existing_sso_users        = var.existing_sso_users
  existing_google_sso_users = var.existing_google_sso_users

  # Permission Sets
  permission_sets          = var.permission_sets
  existing_permission_sets = var.existing_permission_sets

  # Account Assignments
  account_assignments = var.account_assignments

  # Applications
  sso_applications = var.sso_applications

  # Access Control Attributes
  sso_instance_access_control_attributes = var.sso_instance_access_control_attributes

  # Tags & Config
  default_tags = var.default_tags
  config_path  = var.config_path
}
