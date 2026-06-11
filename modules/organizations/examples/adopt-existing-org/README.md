# adopt-existing-org — Reference Example

**Module**: `../../` (local — tests the parent organizations module)
**Purpose**: Demonstrates the call-signature for adopting an existing AWS Organization and provisioning a generic OU tree, tag policy, baseline SCPs, and one example vended account.

## What This Example Shows

- `create_organization = false` — adopts the existing org via `data.aws_organizations_organization`
- 2 generic root-level OUs: `Workloads` and `Sandbox`
- 1 example vended account: `example-sandbox` with email `aws+sandbox@example.com` placed in the `Sandbox` OU
- Tag policy enforcing 4 mandatory keys: `CostCenter`, `Owner`, `Environment`, `ManagedBy`
- Baseline SCPs (opt-in): deny-leave-org, deny-root-user-actions, require-mandatory-tags

## ClickOps Prerequisites

Before running `terraform plan`, complete these two steps in the AWS Console:

1. **Verify AWS Organization exists** — navigate to the AWS Organizations console in the management account and confirm an organization is active. If no organization exists, set `create_organization = true` (valid ONLY for a brand-new account). Most enterprises already have an org — the default `create_organization = false` is correct for them.
2. **Create an S3 state bucket** — provision an S3 bucket for Terraform remote state (or use `-backend=false` for local testing only). S3 native locking (`use_lockfile = true`) is the project standard (ADR-006, no DynamoDB required).

## Usage

```bash
# 1. From the repo root, change to this example directory
cd modules/organizations/examples/adopt-existing-org

# 2. Create a tfvars file — do NOT commit this file
cat > local.auto.tfvars <<'EOF'
aws_region   = "<your-aws-region>"
environment  = "sandbox"
cost_center  = "platform"
owner        = "platform-team@example.com"
EOF

# 3. Initialise and validate (no backend required for local testing)
terraform init -backend=false
terraform validate

# 4. Review the plan (requires real AWS credentials with Organizations access)
terraform plan
```

## Important: Account Creation is Irreversible

`aws_organizations_account` resources **cannot be cleanly destroyed** once the account is bootstrapped. Always review `terraform plan` with a human (HITL) before running `terraform apply` for the first time. See the module README for the full irreversibility warning.

## File Structure

```
modules/organizations/examples/adopt-existing-org/
  main.tf          # Module call — source = "../../" (local module)
  variables.tf     # Input variables (region, tags)
  outputs.tf       # Expose org ID, OU IDs, account IDs, SCP IDs
  versions.tf      # Provider constraints
  README.md        # This file
```

## Reference Only

This example is a call-signature reference — not deployable tenant infrastructure.
Replace all placeholder values (`<your-aws-region>`, `aws+sandbox@example.com`, `platform-team@example.com`) per your enterprise before running `terraform apply`. Account emails must be globally unique across all AWS accounts.

See the full module documentation at: `../../README.md`
