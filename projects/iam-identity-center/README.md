# MVP Identity Center

Deploy APRA-compliant IAM Identity Center from YAML in one Terraform command.

- **Tier**: MVP
- **Cost**: $0.00/month (IAM Identity Center is free)
- **Time to deploy**: ~15 minutes
- **Prerequisites**: AWS SSO enabled in console (cannot be enabled via Terraform), Terraform >= 1.10.0, AWS Provider >= 5.95
- **HITL Required**: No
- **What you get**: 2 permission sets (Admin, ReadOnly), 2 account assignments via YAML config

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## YAML Configuration

Edit `modules/identity-center/configs/permission_sets.yml` to customize permission sets.
Edit `modules/identity-center/configs/account_assignments.yml` to customize assignments.

Non-HCL reviewers (auditors, compliance officers) can review these YAML files directly.
