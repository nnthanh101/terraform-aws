# terraform-aws

> Terraform Registry-publishable modules with ADLC governance, 3-tier testing, and FOCUS 1.2+ FinOps compliance.

## Modules

| Module | Status | Description |
|--------|--------|-------------|
| [iam-identity-center](modules/iam-identity-center/) | stable | AWS IAM Identity Center (SSO) permission sets and assignments |
| [ecs-platform](modules/ecs-platform/) | stub | ECS Fargate platform with ALB and service mesh |
| [fullstack-web](modules/fullstack-web/) | stub | Full-stack web application infrastructure |

## Quick Start

See **[QUICKSTART.md](QUICKSTART.md)** for the 5-command manager workflow (start, validate, release, pre-flight, status).

```bash
task build:env      # Start devcontainer
task ci:quick       # Validate + lint + legal (<60s)
task test:tier1     # Snapshot tests (free, 2-3s)
```

## Development

```bash
task ci:quick           # Fast PR gate: fmt + validate + lint + legal
task ci:full            # Full pipeline: build + test + govern + security
task test:tier1         # Tier 1 snapshot tests (no AWS cost)
task sprint:validate    # 7-gate sprint milestone check
task plan:cost          # Infracost estimate per module
task security:trivy     # Trivy misconfiguration scan
```

## Release

Fully automated: conventional commits → release-please PR → HITL merge → auto-tag → API publish to TFC.
See **[QUICKSTART.md](QUICKSTART.md)** for details. HITL effort: merge one PR.

<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->
