# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.0.0...terraform-aws-v2.1.0) (2026-03-13)

**One tag, 12 modules, zero "works on my machine"** — Unified versioning (ADR-026) delivers a single `terraform-aws-vX.Y.Z` release across all building-block modules. Consumers pin one version, get all 12.

### What Consumers Get

- **Enterprise SSO at scale** — 4-tier landing zone (PlatformTeam, PowerUsers, AuditTeam, SecurityTeam) with YAML-driven permission sets. Auditors review YAML, not HCL. APRA CPS 234 compliant. ([#46](https://github.com/nnthanh101/terraform-aws/issues/46))
- **One-click registry publish** — Push a tag, get a validated module in TFC Private Registry. Pipeline: validate → lint → Tier-1 test → publish → verify ingestion. No manual steps.
- **12 building-block modules available** — acm, alb, cloudfront, ecs, efs, kms, s3, sftp, sso, vpc, waf, web. All pinned to `aws >= 6.28, < 7.0` and `terraform >= 1.11.0`.

### What Changed (for module consumers)

- **Single version pin**: `source = "app.terraform.io/oceansoft/sso/aws" version = "2.1.0"` — same pattern for all modules
- **YAML config example**: Permission sets and account assignments in auditor-readable YAML files
- **WAF deprecated lookup fixed**: 6 `lookup()` calls updated to 3-arg form (no consumer action needed)

### Under the Hood (CI/CD)

- Docker-first: all CI in `nnthanh101/terraform:2.6.0` SHA-pinned container
- Checkov: 52 consumer-decision skips (building blocks expose variables, consumers decide security posture)
- Auto-register + auto-publish all modules on release via `registry-sync` job
- docs-sync race condition fixed (`max-parallel: 1`)

## [2.0.0] (2026-03-05)

**The unified versioning epoch.** All 12 AWS modules consolidated under a single semver tag. No more per-module version tracking. Pin once, use everywhere.

### What Consumers Get

- **12 production-ready AWS modules** — Building blocks for Landing Zone infrastructure: ACM, ALB, CloudFront, ECS, EFS, KMS, S3, SFTP, SSO (IAM Identity Center), VPC, WAF, Web
- **TFC Private Registry** — All modules available at `app.terraform.io/oceansoft/<module>/aws`
- **Compliance out-of-the-box** — Apache 2.0 licensed, APRA CPS 234 tagging, FOCUS cost tags, upstream attribution in NOTICE.txt

### Under the Hood

- Docker-first CI/CD pipeline (`nnthanh101/terraform:2.6.0`)
- release-please for automated semver and changelog
- Checkov + tflint security scanning

## [1.1.0] - 2026-02-28

### What Consumers Get

- **TFC Registry works** — Root wrapper module fixes SIC-001 "no healthy versions". `source = "app.terraform.io/oceansoft/iam-identity-center/aws"` now resolves.
- **Production multi-account example** — 4-account Landing Zone (Management, Security-Audit, Shared-Services, Workloads) with ABAC and permission boundaries.

### Under the Hood

- VERSION alignment between root and `modules/sso/` (ADR-015)
- 18 Tier-1 snapshot tests passing

## [1.0.0] - 2026-02-26

### What Consumers Get

- **IAM Identity Center module** — Enterprise SSO with YAML configuration layer for APRA CPS 234 audit compliance. Derived from `aws-ia/terraform-aws-sso` v1.0.4 (Apache-2.0).
- **8 examples** — Single-account, multi-account, ABAC, and permission boundary patterns
- **8 Tier-1 tests** — Snapshot tests for rapid validation

### Under the Hood

- ADR-001 through ADR-007 architectural decisions
- CI pipeline with validate, lint, legal, governance, test gates
- Registry publication workflow
- Apache 2.0 license with NOTICE.txt attribution

[2.1.0]: https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.0.0...terraform-aws-v2.1.0
[2.0.0]: https://github.com/nnthanh101/terraform-aws/releases/tag/terraform-aws-v2.0.0
[1.1.0]: https://github.com/nnthanh101/terraform-aws/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nnthanh101/terraform-aws/releases/tag/v1.0.0
