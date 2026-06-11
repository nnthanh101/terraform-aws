# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.
#
# Reference: adopt-existing-org — per-module example for the organizations module.
#
# What this shows:
#   - create_organization = false (default) — adopts the existing org via data source
#   - 2 generic root-level OUs: Workloads, Sandbox
#   - 1 example vended account: example-sandbox in the Sandbox OU
#   - Tag policy with 4 mandatory keys
#   - Baseline SCPs: deny-leave-org + deny-root-user-actions + require-mandatory-tags
#
# ClickOps prerequisites (must be done ONCE before terraform plan):
#   1. Ensure an AWS Organization already exists in the management account (the default
#      create_organization = false assumes an existing org). If no org exists, set
#      create_organization = true ONLY for a brand-new account.
#   2. Create an S3 bucket for remote state and update backend.tf (or use -backend=false
#      for local testing).
#
# IMPORTANT: aws_organizations_account creation is IRREVERSIBLE. Once a member account
# is provisioned it cannot be cleanly destroyed via Terraform. Always review terraform plan
# with a human before running terraform apply for the first time.
#
# This is a REFERENCE ROOT — replace all var.* placeholder values before running
# terraform apply. Account emails must be globally unique across all AWS accounts.

provider "aws" {
  region = var.aws_region
}

module "organizations" {
  source = "../../"

  # ---------------------------------------------------------------------------
  # Adopt the existing organization — do NOT create a new one.
  # create_organization = true only for brand-new accounts with no existing org.
  # ---------------------------------------------------------------------------
  create_organization = false

  # ---------------------------------------------------------------------------
  # Organizational Units — 2 generic root-level OUs.
  # Extend with nested OUs by adding parent = "<OU-name>" entries.
  # ---------------------------------------------------------------------------
  organizational_units = {
    Workloads = { parent = "ROOT" }
    Sandbox   = { parent = "ROOT" }
  }

  # ---------------------------------------------------------------------------
  # Account vending — 1 generic sandbox account.
  # IRREVERSIBLE once applied. Replace email with a real, globally unique address.
  # ---------------------------------------------------------------------------
  accounts = {
    example-sandbox = {
      name  = "example-sandbox"
      email = "aws+sandbox@example.com"
      ou    = "Sandbox"
      tags = {
        CostCenter = var.cost_center
        Owner      = var.owner
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Tag policy — enforces 4 mandatory tag keys at org root.
  # ---------------------------------------------------------------------------
  tag_policy = {
    enabled        = true
    mandatory_keys = ["CostCenter", "Owner", "Environment", "ManagedBy"]
    environment_allowed_values = [
      "sandbox", "dev", "test", "sit", "uat", "preprod", "prod", "dr"
    ]
    target_ous = []
  }

  # ---------------------------------------------------------------------------
  # Baseline SCPs (opt-in):
  #   deny-leave-organization   — prevents member accounts from leaving the org
  #   deny-root-user-actions    — blocks interactive root user API calls
  #   require-mandatory-tags    — denies resource creation without mandatory tag keys
  # ---------------------------------------------------------------------------
  baseline_scps = true

  # ---------------------------------------------------------------------------
  # Tags — 4 required keys: CostCenter, Owner, Environment, ManagedBy.
  # Copied from global/global_variables.tf 5-tier SSOT structure.
  # ---------------------------------------------------------------------------
  tags = {
    CostCenter  = var.cost_center
    Owner       = var.owner
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
