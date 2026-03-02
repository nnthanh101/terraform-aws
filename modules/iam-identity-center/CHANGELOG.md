# Changelog

All notable changes to the `iam-identity-center` module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1](https://github.com/nnthanh101/terraform-aws/compare/iam-identity-center/v1.2.0...iam-identity-center/v1.2.1) (2026-03-02)


### CI/CD

* Fix naming audit, checkov scoping, and registry management ([#50](https://github.com/nnthanh101/terraform-aws/issues/50)) ([0ed8da4](https://github.com/nnthanh101/terraform-aws/commit/0ed8da444c2346c2ab1a3756a6b7a2baab6dee57))

## [1.2.0](https://github.com/nnthanh101/terraform-aws/compare/iam-identity-center/v1.1.8...iam-identity-center/v1.2.0) (2026-03-01)


### Features

* **iam-identity-center:** enterprise SSO landing zone v1.1.9 ([#46](https://github.com/nnthanh101/terraform-aws/issues/46)) ([19bfa23](https://github.com/nnthanh101/terraform-aws/commit/19bfa23e052ecf8eb42a2ce41479a6d96731956b))

## [1.1.9] (2026-03-02)

### Enterprise SSO Landing Zone — Production Ready

- 4-tier RBAC model deployed: Admin (1h), PowerUser (4h), ReadOnly (8h), SecurityAudit (8h) — enforcing least-privilege session durations per APRA CPS 234
- 16 AWS resources converged: 4 SSO groups, 4 permission sets, 4 managed policies, 4 account assignments — zero drift
- 18 Tier 1 snapshot tests passing, 8/8 deployment verification checks, 4/4 cross-validation (ADLC vs CLI vs S3 state)
- E2E validated: code = deployed = TFC Registry (`oceansoft/iam-identity-center/aws`)

### Compliance and Governance

- APRA CPS 234: separation of duties via CODEOWNERS, RBAC tiering with session duration controls
- Apache 2.0: LICENSE + NOTICE.txt + file-level copyright headers
- FOCUS 1.2+: cost allocation tags on all resources
- 3-way cross-validation evidence: ADLC task output vs raw AWS CLI vs Terraform state

### Module Capabilities

- Wrapper module consuming `aws-ia/terraform-aws-iam-identity-center` v1.0.4
- YAML-decoded inputs for SSO users, groups, permission sets, and account assignments
- Account-level SSO support (standalone accounts without AWS Organizations)
- 8 consumer example patterns covering common enterprise SSO scenarios
- S3 native state locking (`use_lockfile = true`, no DynamoDB)

### Technical

- Terraform >= 1.11.0, AWS Provider >= 6.28, < 7.0
- Registry: `oceansoft/iam-identity-center/aws` at `app.terraform.io/app/oceansoft/`
- CI/CD: release-please automation, Checkov + InfraCost + Trivy scanning
- ADRs: 001 (naming), 003 (providers), 004 (3-tier testing), 006 (state locking), 007 (upstream strategy)
