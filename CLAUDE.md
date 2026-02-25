# terraform-aws

> Terraform Registry-publishable modules with ADLC governance, 3-tier testing, and FOCUS 1.2+ FinOps compliance
> **Version:** 0.1.0 | **Terraform:** >= 1.10.0 | **AWS Provider:** >= 5.95, < 7.0

## Architecture

- **3 Domains**: identity-center, ecs-platform, fullstack-web
- **Wrapper Pattern**: Consume upstream modules via `source`, not copy-paste
- **State**: S3 native locking (`use_lockfile = true`), NO DynamoDB (ADR-006)
- **Region**: ap-southeast-2 (primary), us-east-1 (Identity Center)

## ADRs

| ADR | Decision |
|-----|----------|
| ADR-001 | Module naming: kebab-case |
| ADR-002 | Registry structure: nnthanh101/terraform-aws/aws |
| ADR-003 | Provider constraints: >= 5.95, < 7.0 |
| ADR-004 | 3-tier testing: snapshot/localstack/integration |
| ADR-005 | Example naming: {stage}-{domain}-{variant} |
| ADR-006 | S3 native state locking (no DynamoDB) |

## Quick Commands

```bash
task validate       # terraform fmt + validate
task lint           # tflint + checkov
task test           # 3-tier test suite
task legal:audit    # Apache 2.0 compliance (4 checks)
task ci:quick       # Fast CI pipeline (validate + lint + legal)
task governance:score # Constitutional checkpoint scoring
task cost           # Infracost estimate
```

## Evidence

All evidence goes to `tmp/terraform-aws/`. Never claim completion without evidence files.

## Rules

- NO git add/commit/push (HITL handles version control)
- S3 native locking (use_lockfile=true), NO DynamoDB
- Wrapper pattern for upstream modules
- KISS/DRY/LEAN
