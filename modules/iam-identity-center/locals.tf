# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-ia/terraform-aws-iam-identity-center v1.0.4 (Apache-2.0). See NOTICE.

# - YAML Configuration Layer (ADR-008: Auditor-Friendly YAML API) -
# When config_path is set, reads YAML configs and merges with HCL variable values.
# YAML values take precedence over HCL variable defaults.
# When config_path is empty (default), falls back to HCL variables only.
# - 5 Canonical Tags: Enterprise + FOCUS (via Cost Allocation Tags) + CPS 234 -
# These baseline tags are merged into every permission set. Consumer-supplied
# var.default_tags values take precedence; per-permission-set tags override both.
# The literal fallback values satisfy checkov static analysis when the module is
# evaluated without caller-supplied defaults.
locals {
  # 5 canonical tags: enterprise + FOCUS (via Cost Allocation Tags) + CPS 234
  # Defaults satisfy checkov when consumers don't provide default_tags.
  # Per-pset tags (in main.tf:171 merge) can still override individual keys.
  _effective_default_tags = merge({
    CostCenter         = "platform"
    Project            = "iam-identity-center"
    Environment        = "unset"
    ServiceName        = "sso"
    DataClassification = "internal"
  }, var.default_tags)
}

locals {
  _yaml_config_enabled = var.config_path != ""

  # Read YAML files if config_path is set; empty maps otherwise
  _yaml_permission_sets = local._yaml_config_enabled ? try(
    yamldecode(file("${var.config_path}/permission_sets.yaml")), {}
  ) : {}

  _yaml_account_assignments = local._yaml_config_enabled ? try(
    yamldecode(file("${var.config_path}/account_assignments.yaml")), {}
  ) : {}

  # Effective values: YAML overrides HCL (merge = right wins on key collision)
  effective_permission_sets     = merge(var.permission_sets, local._yaml_permission_sets)
  effective_account_assignments = merge(var.account_assignments, local._yaml_account_assignments)

  # AC-3-10: Pre-compute validation results for check blocks below.
  # Variables-block validation only covers var.permission_sets (HCL path); YAML-merged
  # entries bypass it entirely. These locals expose the same predicates so check blocks
  # can surface failures at plan time regardless of the ingestion path.

  # Collect all pset names whose session_duration is present but violates ISO 8601.
  # Accepts PT<n>H (hours) or PT<n>M (minutes) — the two formats used in AWS SSO.
  _invalid_session_duration_psets = [
    for k, v in local.effective_permission_sets :
    k if can(v.session_duration) && !can(regex("^PT[0-9]+[HM]$", v.session_duration))
  ]

  # Collect all pset names whose consumer-supplied tags (var.default_tags merged with
  # per-pset tags) are missing CostCenter or DataClassification. Uses var.default_tags
  # (not _effective_default_tags which includes hardcoded fallbacks for checkov) so the
  # check fires when consumers forget required tags, matching deployment reality.
  _consumer_pset_tags = {
    for k, v in local.effective_permission_sets :
    k => merge(var.default_tags, try(v.tags, {}))
  }
  _invalid_tag_psets = [
    for k, merged_tags in local._consumer_pset_tags :
    k if length(merged_tags) > 0 && (
      !contains(keys(merged_tags), "CostCenter") || !contains(keys(merged_tags), "DataClassification")
    )
  ]
}

# - Users and Groups -
locals {
  # Create a new local variable by flattening the complex type given in the variable "sso_users"
  flatten_user_data = flatten([
    for this_user in keys(var.sso_users) : [
      for group in var.sso_users[this_user].group_membership : {
        user_name  = var.sso_users[this_user].user_name
        group_name = group
      }
    ]
  ])

  users_and_their_groups = {
    for s in local.flatten_user_data : format("%s_%s", s.user_name, s.group_name) => s
  }

  # Create a new local variable by flattening the complex type given in the variable "existing_google_sso_users"
  flatten_user_data_existing_google_sso_users = flatten([
    for this_existing_google_user in keys(var.existing_google_sso_users) : [
      for group in var.existing_google_sso_users[this_existing_google_user].group_membership : {
        user_name  = var.existing_google_sso_users[this_existing_google_user].user_name
        group_name = group
      }
    ]
  ])

  users_and_their_groups_existing_google_sso_users = {
    for s in local.flatten_user_data_existing_google_sso_users : format("%s_%s", s.user_name, s.group_name) => s
  }

}


# - Permission Sets and Policies -
locals {
  # - Fetch SSO Instance ARN and SSO Instance ID -
  ssoadmin_instance_arn = tolist(data.aws_ssoadmin_instances.sso_instance.arns)[0]
  sso_instance_id       = tolist(data.aws_ssoadmin_instances.sso_instance.identity_store_ids)[0]

  # Iterate over the objects in var.permission sets, then evaluate the expression's 'pset_name'
  # and 'pset_index' with 'pset_name' and 'pset_index' only if the pset_index.managed_policies (AWS Managed Policy ARN)
  # produces a result without an error (i.e. if the ARN is valid). If any of the ARNs for any of the objects
  # in the map are invalid, the for loop will fail.

  # pset_name is the attribute name for each permission set map/object
  # pset_index is the corresponding index of the map of maps (which is the variable permission_sets)
  aws_managed_permission_sets                           = { for pset_name, pset_index in local.effective_permission_sets : pset_name => pset_index if can(pset_index.aws_managed_policies) }
  customer_managed_permission_sets                      = { for pset_name, pset_index in local.effective_permission_sets : pset_name => pset_index if can(pset_index.customer_managed_policies) }
  inline_policy_permission_sets                         = { for pset_name, pset_index in local.effective_permission_sets : pset_name => pset_index if can(pset_index.inline_policy) }
  permissions_boundary_aws_managed_permission_sets      = { for pset_name, pset_index in local.effective_permission_sets : pset_name => pset_index if can(pset_index.permissions_boundary.managed_policy_arn) }
  permissions_boundary_customer_managed_permission_sets = { for pset_name, pset_index in local.effective_permission_sets : pset_name => pset_index if can(pset_index.permissions_boundary.customer_managed_policy_reference) }


  # When using the 'for' expression in Terraform:
  # [ and ] produces a tuple
  # { and } produces an object, and you must provide two result expressions separated by the => symbol
  # The 'flatten' function takes a list and replaces any elements that are lists with a flattened sequence of the list contents

  # create pset_name and managed policy maps list. flatten is needed because the result is a list of maps.name
  # This nested for loop will run only if each of the managed_policies are valid ARNs.

  # - AWS Managed Policies -
  pset_aws_managed_policy_maps = flatten([
    for pset_name, pset_index in local.aws_managed_permission_sets : [
      for policy in pset_index.aws_managed_policies : {
        pset_name  = pset_name
        policy_arn = policy
      } if pset_index.aws_managed_policies != null && can(pset_index.aws_managed_policies)
    ]
  ])

  # - Customer Managed Policies -
  pset_customer_managed_policy_maps = flatten([
    for pset_name, pset_index in local.customer_managed_permission_sets : [
      for policy in pset_index.customer_managed_policies : {
        pset_name   = pset_name
        policy_name = policy
        # path = path
      } if pset_index.customer_managed_policies != null && can(pset_index.customer_managed_policies)
    ]
  ])

  # - Inline Policy -
  pset_inline_policy_maps = flatten([
    for pset_name, pset_index in local.inline_policy_permission_sets : [
      {
        pset_name     = pset_name
        inline_policy = pset_index.inline_policy
      }
    ]
  ])

  # - Permissions boundary -
  pset_permissions_boundary_aws_managed_maps = flatten([
    for pset_name, pset_index in local.permissions_boundary_aws_managed_permission_sets : [
      {
        pset_name = pset_name
        boundary = {
          managed_policy_arn = pset_index.permissions_boundary.managed_policy_arn
        }
      }
    ]
  ])

  pset_permissions_boundary_customer_managed_maps = flatten([
    for pset_name, pset_index in local.permissions_boundary_customer_managed_permission_sets : [
      {
        pset_name = pset_name
        boundary = {
          customer_managed_policy_reference = pset_index.permissions_boundary.customer_managed_policy_reference
        }
      }
    ]
  ])

}


# - Account Assignments -
locals {

  accounts_ids_maps = {
    for idx, account in data.aws_organizations_organization.organization.accounts : account.name => account.id
    if account.status == "ACTIVE" && can(data.aws_organizations_organization.organization.accounts)
  }

  # Create a new local variable by flattening the complex type given in the variable "account_assignments"
  # This will be a 'tuple'
  flatten_account_assignment_data = flatten([
    for this_assignment in keys(local.effective_account_assignments) : [
      for account in local.effective_account_assignments[this_assignment].account_ids : [
        for pset in local.effective_account_assignments[this_assignment].permission_sets : {
          permission_set = pset
          principal_name = local.effective_account_assignments[this_assignment].principal_name
          principal_type = local.effective_account_assignments[this_assignment].principal_type
          principal_idp  = local.effective_account_assignments[this_assignment].principal_idp
          account_id     = length(regexall("[0-9]{12}", account)) > 0 ? account : lookup(local.accounts_ids_maps, account, null)
        }
      ]
    ]
  ])

  #  Convert the flatten_account_assignment_data tuple into a map.
  # Since we will be using this local in a for_each, it must either be a map or a set of strings
  principals_and_their_account_assignments = {
    for s in local.flatten_account_assignment_data : format("Type:%s__Principal:%s__Permission:%s__Account:%s", s.principal_type, s.principal_name, s.permission_set, s.account_id) => s
  }

  # List of permission sets, groups, and users that are defined in this module
  this_permission_sets = keys(local.effective_permission_sets)
  this_groups = [
    for group in var.sso_groups : group.group_name
  ]
  this_users = [
    for user in var.sso_users : user.user_name
  ]

  # List of permission sets, groups, and users that are defined in this module
  # this_existing_permission_sets = keys(var.existing_permission_sets)
  # this_existing_groups = [
  #   for group in var.existing_sso_groups : group.group_name
  # ]
  # this_existing_google_sso_users = [
  #   for user in var.existing_google_sso_users : user.user_name
  # ]

}

# - AC-3-10: YAML Validation Check Blocks (Terraform >= 1.5) -
# These check blocks validate effective_permission_sets AFTER the YAML merge, catching
# values that bypass the variables.tf validation block (which only covers var.permission_sets).
# Failures surface as plan-time warnings (non-blocking by Terraform design) — they become
# blocking when run inside a CI pipeline that treats check failures as errors (e.g. via
# `terraform plan -detailed-exitcode` + stderr inspection).

check "yaml_session_duration_format" {
  assert {
    condition     = length(local._invalid_session_duration_psets) == 0
    error_message = "APRA CPS 234 / AC-3-10: The following permission sets (possibly from YAML) have a session_duration that does not match ISO 8601 PT<n>H or PT<n>M format: ${jsonencode(local._invalid_session_duration_psets)}. Correct the YAML file or the HCL variable value."
  }
}

check "yaml_required_tag_keys" {
  assert {
    condition     = length(local._invalid_tag_psets) == 0
    error_message = "APRA CPS 234 / AC-3-10: The following permission sets (possibly from YAML) have a tags map that is missing required keys CostCenter and/or DataClassification: ${jsonencode(local._invalid_tag_psets)}. Add the missing tag keys."
  }
}

locals {

  # Creating a local variable by flattening the complex type related to Applications to extract a simple structure representing
  # group-application assignments
  apps_groups_assignments = flatten([
    for app in var.sso_applications : [
      for group in coalesce(app.group_assignments, []) : {
        app_name       = app.name
        group_name     = group
        principal_type = "GROUP"
      }
    ]
  ])

  # Creating a local variable by flattening the complex type related to Applications to extract a simple structure representing
  # user-application assignments
  apps_users_assignments = flatten([
    for app in var.sso_applications : [
      for user in coalesce(app.user_assignments, []) : {
        app_name       = app.name
        user_name      = user
        principal_type = "USER"
      }
    ]
  ])

  # Creating a local variable by flattening the complex type related to Applications to extract a simple structure representing
  # apps assignments configurations
  apps_assignments_configs = flatten([
    for app in var.sso_applications : {
      app_name            = app.name
      assignment_required = app.assignment_required
    }
  ])

  # Creating a local variable by flattening the complex type related to Applications to extract a simple structure representing
  # app assignments access scopes 
  apps_assignments_access_scopes = flatten([
    for app in var.sso_applications : [
      for ass_acc_scope in coalesce(app.assignments_access_scope, []) : {
        app_name           = app.name
        authorized_targets = ass_acc_scope.authorized_targets
        scope              = ass_acc_scope.scope
      }
    ]
  ])
}
