# IAM Identity Center (SSO) — Management Account

Migrated from `projects/sso/` to align with the `accounts/` convention (per `accounts/xops/` pattern).

## State Migration

The Terraform state must be migrated from the old key to the new key:

```bash
# Option A: S3 copy (preserves history, recommended)
aws s3 cp \
  s3://${ACCOUNT_ID}-tfstate-ap-southeast-2/projects/iam-identity-center/terraform.tfstate \
  s3://${ACCOUNT_ID}-tfstate-ap-southeast-2/accounts/management-account/terraform.tfstate

# Option B: terraform init -migrate-state (interactive)
cd accounts/management-account/
terraform init \
  -backend-config="bucket=${ACCOUNT_ID}-tfstate-ap-southeast-2" \
  -backend-config="region=ap-southeast-2" \
  -migrate-state

# Verify
terraform plan  # Should show no changes
```

## Known State Key Discrepancy

- `backend.tf` declared key: `projects/sso/terraform.tfstate`
- Actual S3 key used: `projects/iam-identity-center/terraform.tfstate`
- New key after migration: `accounts/management-account/terraform.tfstate`

## Deployment

```bash
terraform init -backend-config="bucket=${ACCOUNT_ID}-tfstate-ap-southeast-2" -backend-config="region=ap-southeast-2"
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Architecture

- 4 SSO groups: PlatformTeam, PowerUsers, AuditTeam, SecurityTeam
- 4 permission sets: Admin (1h), PowerUser (4h), ReadOnly (8h), SecurityAudit (8h)
- YAML-driven config in `config/` for auditor-friendly review
- APRA CPS 234 least-privilege session durations
