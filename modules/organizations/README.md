# AWS Organizations Terraform Module

Generic, reusable Terraform module for AWS Landing Zone Organizations foundation.

## Features

- Adopt an existing AWS Organization (default) or create a new one
- Dynamic OU tree with up to 2 levels of nesting (root + child), driven by a name→parent map
- Account vending via `aws_organizations_account` for_each — accounts provisioned from a variable map
- TAG_POLICY with configurable mandatory keys and Environment enum enforced at org root or named OUs
- Baseline SCPs (opt-in): deny-leave-org, deny-root-user-actions, require-mandatory-tags
- Caller-supplied SCPs attached to any OU or root
- Delegated administrator registration
- No customer-specific values baked in — all inputs are variables with sensible defaults

## Important

- **Account creation is irreversible.** `aws_organizations_account` resources cannot be cleanly destroyed once the account is provisioned. Always review `terraform plan` with a human before running `terraform apply` against this module for the first time.
- **Org creation**: `create_organization = true` is only valid for a brand-new AWS account that has no existing organization. Most enterprises already have an org — use the default `create_organization = false` (adopt via data source).
- **OU nesting**: this module supports 2-level nesting (root OUs + their direct children). For deeper hierarchies, chain multiple module calls or extend `locals.tf` with additional pass variables.
- **State backend**: this module does not configure a state backend. State locking is the consumer's responsibility (ADR-006: S3 native locking, `use_lockfile = true`).

## Usage

### Adopt existing org, provision OU tree + baseline SCPs

```hcl
module "organizations" {
  source = "../modules/organizations"

  # create_organization = false (default) — adopts the existing org via data source

  organizational_units = {
    Security       = { parent = "ROOT" }
    Infrastructure = { parent = "ROOT" }
    Workloads      = { parent = "ROOT" }
    Prod           = { parent = "Workloads" }
    NonProd        = { parent = "Workloads" }
    Sandbox        = { parent = "ROOT" }
  }

  accounts = {
    platform-sandbox = {
      name  = "platform-sandbox"
      email = "aws+platform-sandbox@example.com"
      ou    = "Sandbox"
      tags  = { CostCenter = "platform" }
    }
  }

  tag_policy = {
    enabled        = true
    mandatory_keys = ["CostCenter", "Owner", "Environment", "ManagedBy"]
    environment_allowed_values = ["sandbox", "dev", "test", "uat", "preprod", "prod", "dr"]
  }

  baseline_scps = true

  tags = {
    CostCenter  = "platform"
    Owner       = "platform-team"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

### Add a caller-supplied SCP

```hcl
module "organizations" {
  source = "../modules/organizations"

  organizational_units = {
    Workloads = { parent = "ROOT" }
  }

  service_control_policies = [
    {
      name        = "deny-s3-public-access"
      description = "Prevents public S3 bucket ACLs"
      target_ou   = "Workloads"
      policy_json = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyS3PublicAccess"
          Effect   = "Deny"
          Action   = ["s3:PutBucketAcl", "s3:PutObjectAcl"]
          Resource = "*"
          Condition = {
            StringEquals = {
              "s3:x-amz-acl" = ["public-read", "public-read-write", "authenticated-read"]
            }
          }
        }]
      })
    }
  ]

  tags = {
    CostCenter  = "platform"
    Owner       = "platform-team"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create_organization` | Create new org (true) or adopt existing (false) | `bool` | `false` | no |
| `organization_feature_set` | Feature set for newly created org | `string` | `"ALL"` | no |
| `organization_enabled_policy_types` | Policy types to enable on the org | `list(string)` | `["TAG_POLICY", "SERVICE_CONTROL_POLICY"]` | no |
| `organization_aws_service_access_principals` | Service principals for Organizations integration | `list(string)` | See variables.tf | no |
| `organizational_units` | Map of OU name → { parent } | `map(object)` | `{}` | no |
| `accounts` | Map of logical key → account spec | `map(object)` | `{}` | no |
| `tag_policy` | Tag policy configuration | `object` | `{}` | no |
| `baseline_scps` | Enable baseline SCP set | `bool` | `false` | no |
| `service_control_policies` | Caller-supplied SCPs | `list(object)` | `[]` | no |
| `delegated_administrators` | Delegated admin registrations | `map(object)` | `{}` | no |
| `tags` | Tags for module-owned resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `organization_id` | AWS Organization ID |
| `organization_root_id` | Organization root ID (r-xxxx) |
| `ou_ids` | Map of OU name → OU ID |
| `account_ids` | Map of logical account key → account ID |
| `tag_policy_id` | TAG_POLICY ID (null when disabled) |
| `baseline_scp_ids` | Map of baseline SCP name → policy ID |
| `caller_scp_ids` | Map of caller SCP name → policy ID |
| `scp_ids` | Combined map of all SCP name → policy ID |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0 |
| aws | >= 6.28, < 7.0 |

## License

Apache-2.0. Copyright 2026 nnthanh101@gmail.com.
