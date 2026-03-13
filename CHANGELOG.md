# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.0.0...terraform-aws-v2.1.0) (2026-03-13)


### Features

* add yaml-config-path example     → bumps MINOR (1.2.1 → 1.3.0) ([d2a44c3](https://github.com/nnthanh101/terraform-aws/commit/d2a44c3547ad5dfa4d253153ea78bbfb510705bb))
* **iam-identity-center:** enterprise SSO landing zone v1.1.9 ([#46](https://github.com/nnthanh101/terraform-aws/issues/46)) ([19bfa23](https://github.com/nnthanh101/terraform-aws/commit/19bfa23e052ecf8eb42a2ce41479a6d96731956b))
* workflows/registry-publish.yml ([4abaa43](https://github.com/nnthanh101/terraform-aws/commit/4abaa43aff12f5f97a679eabed1ccd458f8f4752))


### Bug Fixes

* fix:  ([29bed08](https://github.com/nnthanh101/terraform-aws/commit/29bed08d97e954560de249fb35e17f4f630d26b4))
* **ci:** registry-publish checkout HEAD for dispatch, exclude vendor dirs from naming audi ([9a0636f](https://github.com/nnthanh101/terraform-aws/commit/9a0636f9b168e0e4c7f192476db8897f5be2dccb))
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


### Documentation

* auto-generate ecs module README [skip ci] ([8493f4b](https://github.com/nnthanh101/terraform-aws/commit/8493f4b6b363a705f88fb617f67979475897b466))
* auto-generate ecs module README [skip ci] ([dabde3e](https://github.com/nnthanh101/terraform-aws/commit/dabde3e3526baaf39774c55f04eef8dcefab9a63))
* auto-generate ecs module README [skip ci] ([601d1d9](https://github.com/nnthanh101/terraform-aws/commit/601d1d9d7a895a97941d69b9528ad6c688a8783f))
* auto-generate module README [skip ci] ([24668c6](https://github.com/nnthanh101/terraform-aws/commit/24668c65df2303231c00de9f38fb688a3ebf4381))
* auto-generate sftp module README [skip ci] ([741c47f](https://github.com/nnthanh101/terraform-aws/commit/741c47f176929f608e8378a444867d3f96587b5b))


### CI/CD

* Add ECS Checkov skip policy for upstream module checks ([d51837c](https://github.com/nnthanh101/terraform-aws/commit/d51837ce49e8a67ce61bf86ed3ab2068f0fe9100))
* add workflow_dispatch trigger to registry-publish for manual TFC sync ([26fe46c](https://github.com/nnthanh101/terraform-aws/commit/26fe46cf9171a9644943a4f8abea0341ce49a7fc))
* auto-trigger TFC registry-publish after release-please creates a release ([420acb5](https://github.com/nnthanh101/terraform-aws/commit/420acb52e8759e16f58c32d5f85ded3863cdba8b))
* Fix naming audit, checkov scoping, and registry management ([#50](https://github.com/nnthanh101/terraform-aws/issues/50)) ([0ed8da4](https://github.com/nnthanh101/terraform-aws/commit/0ed8da444c2346c2ab1a3756a6b7a2baab6dee57))

## [1.1.0] - 2026-02-28

### Added

- **Root wrapper module** for TFC Private Registry ingestion — 4 thin pass-through `.tf`
  files (`versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`) at repo root delegate to
  `modules/sso/` (ADR-007 wrapper pattern). Fixes SIC-001 "no healthy versions".
- **Production multi-account landing zone example** (`modules/sso/examples/production-multi-account-landing-zone/`) — 4-account structure (Management, Security-Audit, Shared-Services, Workloads) with ABAC, permission boundaries, and APRA CPS 234 tagging.
- Code quality: decision-table comment in `main.tf` (`principal_idp` routing), `group_membership` documentation in `variables.tf`.

### Changed

- VERSION alignment: root `VERSION` and `modules/sso/VERSION` now track in sync (ADR-015).
- 18 Tier-1 snapshot tests (all passing).

## [1.0.0] - 2026-02-26

### Added

- **IAM Identity Center module** (`modules/sso/`) — clone + rebrand of
  `aws-ia/terraform-aws-sso` v1.0.4 (Apache-2.0), with AWSCC provider
  stripped and YAML configuration layer added for APRA CPS 234 audit compliance.
  - 14 resource types: `aws_identitystore_group`, `aws_identitystore_user`,
    `aws_identitystore_group_membership`, `aws_ssoadmin_permission_set`,
    `aws_ssoadmin_managed_policy_attachment`, `aws_ssoadmin_customer_managed_policy_attachment`,
    `aws_ssoadmin_permission_set_inline_policy`, `aws_ssoadmin_permissions_boundary_attachment`,
    `aws_ssoadmin_account_assignment`, `aws_ssoadmin_application`, and more.
  - 10 outputs: ARNs, IDs, assignment maps for downstream composition.
  - 30+ variable attributes for full SCIM user profiles, permission sets, ABAC.
  - YAML config API via `yamldecode()` in `locals.tf` (ADR-008).
- 8 examples in `modules/sso/examples/` covering single-account,
  multi-account, ABAC, and permission boundary patterns.
- 8 Tier-1 snapshot tests in `modules/sso/tests/`.
- ADR-001 through ADR-007 documenting architectural decisions.
- CI pipeline (`.github/workflows/ci.yml`) with validate, lint, legal, governance,
  test, lock-verify, and security jobs.
- Registry publication workflow (`.github/workflows/registry-publish.yml`).
- Apache 2.0 license with NOTICE.txt attribution to upstream `aws-ia`.
- CODEOWNERS with per-path review rules (APRA CPS 234 Attachment H).

### Attribution

This module is derived from [`aws-ia/terraform-aws-sso`](https://github.com/aws-ia/terraform-aws-sso)
v1.0.4, licensed under Apache License 2.0. See `modules/sso/NOTICE.txt`.

[1.1.0]: https://github.com/nnthanh101/terraform-aws/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nnthanh101/terraform-aws/releases/tag/v1.0.0
