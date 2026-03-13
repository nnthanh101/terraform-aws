# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.1.0...terraform-aws-v2.2.0) (2026-03-13)


### Features

* add yaml-config-path example     → bumps MINOR (1.2.1 → 1.3.0) ([d2a44c3](https://github.com/nnthanh101/terraform-aws/commit/d2a44c3547ad5dfa4d253153ea78bbfb510705bb))
* **iam-identity-center:** enterprise SSO landing zone v1.1.9 ([#46](https://github.com/nnthanh101/terraform-aws/issues/46)) ([19bfa23](https://github.com/nnthanh101/terraform-aws/commit/19bfa23e052ecf8eb42a2ce41479a6d96731956b))
* workflows/registry-publish.yml ([4abaa43](https://github.com/nnthanh101/terraform-aws/commit/4abaa43aff12f5f97a679eabed1ccd458f8f4752))


### Bug Fixes

* fix:  ([29bed08](https://github.com/nnthanh101/terraform-aws/commit/29bed08d97e954560de249fb35e17f4f630d26b4))
* **ci:** registry-publish checkout HEAD for dispatch, exclude vendor dirs from naming audi ([9a0636f](https://github.com/nnthanh101/terraform-aws/commit/9a0636f9b168e0e4c7f192476db8897f5be2dccb))
* docker-first ([ce5d396](https://github.com/nnthanh101/terraform-aws/commit/ce5d396ff543971c8513d7af1e03e89eb9c36acf))
* docker-first ([d688c7b](https://github.com/nnthanh101/terraform-aws/commit/d688c7b4aeed44c121b1deacdc430888d7ff9864))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([0bb734b](https://github.com/nnthanh101/terraform-aws/commit/0bb734b3323550244ba2488f5d0b689598f9d25f))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([6d7b05d](https://github.com/nnthanh101/terraform-aws/commit/6d7b05dd9a5f677bb1eb8b5aaae8296723f04015))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([c1f614d](https://github.com/nnthanh101/terraform-aws/commit/c1f614d02263b6fc52db21d9f2cf7e2236a30e63))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([c1f614d](https://github.com/nnthanh101/terraform-aws/commit/c1f614d02263b6fc52db21d9f2cf7e2236a30e63))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([283f174](https://github.com/nnthanh101/terraform-aws/commit/283f1748cd5c3c582806942cf68b1e33bfbb2050))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([27a2c5b](https://github.com/nnthanh101/terraform-aws/commit/27a2c5b9ce16878ff53883bdb963fe3fb37e336e))
* Github Actions CI/CD + InfraCost +  Checkov APRA+FOCUS tag failures ([71f4fca](https://github.com/nnthanh101/terraform-aws/commit/71f4fcabf500130798b64d725e8c6902235bb080))
* Github Actions CI/CD + InfraCost + Checkov APRA+FOCUS tag failures ([3982cae](https://github.com/nnthanh101/terraform-aws/commit/3982cae7d9a54c8d37d09fb21e014eea5f572e85))
* How release-please Auto-Version Works ([d2a44c3](https://github.com/nnthanh101/terraform-aws/commit/d2a44c3547ad5dfa4d253153ea78bbfb510705bb))
* multi-module trigger-publish — iterate all 3 component tags, not just IAM IC ([9fe8d82](https://github.com/nnthanh101/terraform-aws/commit/9fe8d82fccfc6127a15e3e8764743ba8bbe10c10))
* registry-publish.yml ([c1aa472](https://github.com/nnthanh101/terraform-aws/commit/c1aa47284cb8235dba1c1cdcdb114bf71e2c40ea))
* sync VERSION files to match release-please manifest (1.1.1 → 1.1.2) ([#27](https://github.com/nnthanh101/terraform-aws/issues/27)) ([ad2eb92](https://github.com/nnthanh101/terraform-aws/commit/ad2eb92b2f1b2cd63deba258ecf9975b8c20759a))
* update NOTICE.txt with sprint modifications (4-tier SSO, ADR-011 naming) ([444c87f](https://github.com/nnthanh101/terraform-aws/commit/444c87fdaa969cf2ecc089635e7209edcdf0140e))
* use correct release-please v4 monorepo output keys (modules/X--tag_name not X--tag_name) ([39a9eb1](https://github.com/nnthanh101/terraform-aws/commit/39a9eb1f760405885b6edacb7b06e5960687e8e8))

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
