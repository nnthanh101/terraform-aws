# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-28

### Added

- **Root wrapper module** for TFC Private Registry ingestion — 4 thin pass-through `.tf`
  files (`versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`) at repo root delegate to
  `modules/iam-identity-center/` (ADR-007 wrapper pattern). Fixes SIC-001 "no healthy versions".
- **Production multi-account landing zone example** (`modules/iam-identity-center/examples/production-multi-account-landing-zone/`) — 4-account structure (Management, Security-Audit, Shared-Services, Workloads) with ABAC, permission boundaries, and APRA CPS 234 tagging.
- Code quality: decision-table comment in `main.tf` (`principal_idp` routing), `group_membership` documentation in `variables.tf`.

### Changed

- VERSION alignment: root `VERSION` and `modules/iam-identity-center/VERSION` now track in sync (ADR-015).
- 18 Tier-1 snapshot tests (all passing).

## [1.0.0] - 2026-02-26

### Added

- **IAM Identity Center module** (`modules/iam-identity-center/`) — clone + rebrand of
  `aws-ia/terraform-aws-iam-identity-center` v1.0.4 (Apache-2.0), with AWSCC provider
  stripped and YAML configuration layer added for APRA CPS 234 audit compliance.
  - 14 resource types: `aws_identitystore_group`, `aws_identitystore_user`,
    `aws_identitystore_group_membership`, `aws_ssoadmin_permission_set`,
    `aws_ssoadmin_managed_policy_attachment`, `aws_ssoadmin_customer_managed_policy_attachment`,
    `aws_ssoadmin_permission_set_inline_policy`, `aws_ssoadmin_permissions_boundary_attachment`,
    `aws_ssoadmin_account_assignment`, `aws_ssoadmin_application`, and more.
  - 10 outputs: ARNs, IDs, assignment maps for downstream composition.
  - 30+ variable attributes for full SCIM user profiles, permission sets, ABAC.
  - YAML config API via `yamldecode()` in `locals.tf` (ADR-008).
- 8 examples in `modules/iam-identity-center/examples/` covering single-account,
  multi-account, ABAC, and permission boundary patterns.
- 8 Tier-1 snapshot tests in `modules/iam-identity-center/tests/`.
- ADR-001 through ADR-007 documenting architectural decisions.
- CI pipeline (`.github/workflows/ci.yml`) with validate, lint, legal, governance,
  test, lock-verify, and security jobs.
- Registry publication workflow (`.github/workflows/registry-publish.yml`).
- Apache 2.0 license with NOTICE.txt attribution to upstream `aws-ia`.
- CODEOWNERS with per-path review rules (APRA CPS 234 Attachment H).

### Attribution

This module is derived from [`aws-ia/terraform-aws-iam-identity-center`](https://github.com/aws-ia/terraform-aws-iam-identity-center)
v1.0.4, licensed under Apache License 2.0. See `modules/iam-identity-center/NOTICE.txt`.

[1.1.0]: https://github.com/nnthanh101/terraform-aws/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nnthanh101/terraform-aws/releases/tag/v1.0.0
