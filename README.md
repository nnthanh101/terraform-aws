# terraform-aws

> Enterprise Terraform modules with ADLC governance, 3-tier testing, and FOCUS 1.2+ FinOps compliance — published to HCP Terraform Registry.

[![CI](https://github.com/nnthanh101/terraform-aws/actions/workflows/ci.yml/badge.svg)](https://github.com/nnthanh101/terraform-aws/actions/workflows/ci.yml)
[![Release Please](https://github.com/nnthanh101/terraform-aws/actions/workflows/release-please.yml/badge.svg)](https://github.com/nnthanh101/terraform-aws/actions/workflows/release-please.yml)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.11.0-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS-%3E%3D6.28-FF9900?logo=amazonwebservices)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Registry: oceansoft](https://img.shields.io/badge/Registry-oceansoft%2Fterraform--aws-5C4EE5?logo=terraform)](https://app.terraform.io/app/oceansoft/registry/modules)

## Modules

| Module | Version | Registry | Status | Description |
|--------|---------|----------|--------|-------------|
| [sso](modules/sso/) | `1.2.1` | [oceansoft/sso/aws](https://app.terraform.io/app/oceansoft/registry/modules/private/oceansoft/sso/aws) | stable | AWS IAM Identity Center (SSO) — groups, permission sets, account assignments |
| [ecs](modules/ecs/) | `1.0.0` | [oceansoft/ecs/aws](https://app.terraform.io/app/oceansoft/registry/modules/private/oceansoft/ecs/aws) | active | ECS Fargate platform with ALB, service mesh, and auto-scaling |
| [web](modules/web/) | `1.0.2` | [oceansoft/web/aws](https://app.terraform.io/app/oceansoft/registry/modules/private/oceansoft/web/aws) | active | Full-stack web infrastructure (ALB + CloudFront + WAF + DNS) |
| [acm](modules/acm/) | `1.0.0` | [oceansoft/acm/aws](https://app.terraform.io/app/oceansoft/registry/modules/private/oceansoft/acm/aws) | active | AWS Certificate Manager — DNS/email validation |
| [alb](modules/alb/) | `1.0.0` | [oceansoft/alb/aws](https://app.terraform.io/app/oceansoft/registry/modules/private/oceansoft/alb/aws) | active | Application/Network Load Balancer |
| [cloudfront](modules/cloudfront/) | `1.0.0` | [oceansoft/cloudfront/aws](https://app.terraform.io/app/oceansoft/registry/modules/private/oceansoft/cloudfront/aws) | active | CloudFront CDN distribution |

## 5W1H — Why This Exists

**Who**: Platform engineering teams managing multi-account AWS environments.

**What**: Registry-publishable Terraform modules that codify enterprise landing zone patterns — IAM Identity Center, ECS Fargate, and full-stack web infrastructure.

**When**: From day-one account provisioning through ongoing operational changes — each module is idempotent and drift-aware.

**Where**: HCP Terraform private registry (`app.terraform.io/oceansoft`) with S3 native state locking (no DynamoDB).

**Why**: Manual console clicks don't scale, audit, or reproduce. These modules deliver **consistent, governed, auditable** infrastructure that any team member can deploy with one `terraform apply`.

**How**: Conventional commits trigger release-please PRs. HITL merges one PR. Automated CI validates, tests, scans, and publishes to the registry. Consumers pin a version and go.

## Quick Start

<details>
<summary>Prerequisites</summary>

- [Terraform](https://www.terraform.io/downloads) >= 1.11.0
- [Task](https://taskfile.dev/) (task runner)
- [Docker](https://www.docker.com/) (devcontainer runtime)
- AWS credentials configured (`aws sso login` or env vars)
- HCP Terraform API token (for registry access)

</details>

<details open>
<summary>3-Command Start</summary>

```bash
task build:env      # Start devcontainer (18 tools, pinned SHA)
task ci:quick       # Validate + lint + legal (<60s)
task test:tier1     # Snapshot tests (free, 2-3s)
```

</details>

<details>
<summary>Deploy Lifecycle</summary>

```bash
# 1. Configure credentials
aws sso login --profile aws-sandbox

# 2. Initialize and plan
cd projects/sso
terraform init && terraform plan

# 3. Apply
terraform apply

# 4. Verify
bash scripts/verify-deployment.sh sso
```

See **[QUICKSTART.md](QUICKSTART.md)** for the full 5-command manager workflow.

</details>

## Development

<details open>
<summary>Task Commands</summary>

| Phase | Command | Description |
|-------|---------|-------------|
| Build | `task build:env` | Start devcontainer |
| Build | `task build:validate` | `terraform fmt` + `validate` |
| Build | `task build:lint` | tflint + checkov |
| Test | `task test:tier1` | Tier 1 snapshot tests (free, 2-3s) |
| Test | `task test:ci` | Tier 1 + 2 (no AWS cost) |
| CI | `task ci:quick` | Fast PR gate: fmt + validate + lint + legal |
| CI | `task ci:full` | Full pipeline: build + test + govern + security |
| Govern | `task govern:legal` | Apache 2.0 compliance (5 checks) |
| Govern | `task govern:score` | Constitutional checkpoint scoring (15 checks) |
| Govern | `task sprint:validate` | 7-gate sprint milestone check |
| Cost | `task plan:cost` | Infracost estimate per module |
| Security | `task security:trivy` | Trivy misconfiguration scan |
| Security | `task security:sbom` | CycloneDX SBOM generation |
| Security | `task security:full` | Full pipeline: lint + trivy + SBOM |

</details>

<details>
<summary>Security Pipeline</summary>

Three-stage security scanning — all container-first via devcontainer:

| Stage | Task | Tool | What it checks |
|-------|------|------|----------------|
| Static Analysis | `task build:lint` | Checkov + tflint | IaC misconfigurations, CIS benchmarks, per-module `.checkov.yml` skip policy |
| Vulnerability Scan | `task security:trivy` | Trivy | Known CVEs, misconfigs, secret leaks |
| Supply Chain | `task security:sbom` | Trivy (CycloneDX) | Software Bill of Materials for dependency transparency |
| Full Pipeline | `task security:full` | All above | Orchestrates lint → trivy → SBOM in sequence |

**Agent-driven security** (on-demand via Claude Code):
- `/security:sast` — SAST scanning with shift-left integration
- `security-compliance-engineer` agent — STRIDE threat modeling, red team exercises (non-production), compliance audits

Evidence output: `tmp/terraform-aws/security-scans/`

</details>

## Architecture

- **ADR-001** Module naming: kebab-case (`sso`, not `iam_identity_center`)
- **ADR-002** Registry structure: `oceansoft/terraform-aws/aws` namespace
- **ADR-003** Provider constraints: `>= 6.28, < 7.0`; Terraform `>= 1.11.0`
- **ADR-004** 3-tier testing: snapshot / LocalStack / integration
- **ADR-005** Example naming: `{tier}-{descriptor}` (mvp- / poc- / production-)
- **ADR-006** S3 native state locking (`use_lockfile = true`) — no DynamoDB

## Release

Fully automated via [Release Please](https://github.com/googleapis/release-please):

```
conventional commit → release-please PR → HITL merge → auto-tag → registry publish
```

HITL effort: **merge one PR**. Everything else is automated — version bumps, changelogs, Git tags, and TFC registry publication.

## End-to-End Verification

<details>
<summary>IAM Identity Center — Registry Publication Pipeline</summary>

![IAM Identity Center E2E Verification](README/sso-e2e-verification.gif)

Full pipeline: conventional commit → CI (11 jobs) → Release Please → HITL merge → registry-publish (5 stages) → TFC Registry.

</details>

<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->
