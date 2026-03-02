# Production Multi-Account Landing Zone

Enterprise IAM Identity Center configuration for a 3-account AWS Landing Zone.

## Architecture

- **4 groups**: LZAdministrators, LZPowerUsers, LZReadOnly, LZSecurityAudit
- **4 permission sets**: Admin (PT1H), PowerUser (PT4H), ReadOnly (PT8H), SecurityAudit (PT8H)
- **3 accounts**: Management, Security, Workload
- **ABAC**: Environment and CostCenter attributes for policy conditions

## Usage

Replace account IDs with your actual AWS account IDs or SSM parameter references.

## CPS 234 Compliance

- DataClassification: confidential (all permission sets)
- Session duration: 1H admin, 4H power-user, 8H read-only/audit (max 8H per CKV_APRA_003)
- Separation of duties: Admin and SecurityAudit are separate groups (CKV_APRA_004)
