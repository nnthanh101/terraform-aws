<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->
# terraform-aws

> Terraform Registry-publishable modules with ADLC governance, 3-tier testing, and FOCUS 1.2+ FinOps compliance.

## Modules

| Module | Version | Description | Registry |
|--------|---------|-------------|----------|
| [iam-identity-center](modules/iam-identity-center/) | 1.1.0 | AWS IAM Identity Center (SSO) permission sets and assignments | `oceansoft/terraform-aws/aws//modules/iam-identity-center` |
| [ecs-platform](modules/ecs-platform/) | 1.0.0 | ECS Fargate platform with ALB and service mesh | Stub |
| [fullstack-web](modules/fullstack-web/) | 1.0.0 | Full-stack web application infrastructure | Stub |

## Quick Start

See **[QUICKSTART.md](QUICKSTART.md)** for the 5-command manager workflow.

```bash
task build:env        # 1. Start devcontainer
task ci:quick         # 2. Validate (<60s)
# 3. Release: merge conventional commits → release-please auto-tags
```

## Architecture

- **Registry**: `oceansoft/terraform-aws/aws` (TFC Tag-based publishing)
- **Testing**: 3-tier (snapshot / LocalStack / AWS integration)
- **Governance**: ADLC 6-phase lifecycle, Apache 2.0, APRA CPS 234
- **Region**: ap-southeast-2 (primary), us-east-1 (Identity Center)

## Development

```bash
task ci:quick           # Fast PR gate (<60s)
task ci:full            # Full pipeline
task test:tier1         # Snapshot tests (free, 2-3s)
task sprint:validate    # Sprint milestone check
task registry:preflight MODULE=iam-identity-center  # Pre-release check
```
