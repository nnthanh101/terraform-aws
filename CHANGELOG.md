# Changelog

Enterprise Terraform modules for multi-account AWS landing zones.
Published to [HCP Terraform Registry](https://app.terraform.io/app/oceansoft/registry/private/modules) — pin one version, get all 12 modules.

2-way sync: [github.com/nnthanh101/terraform-aws](https://github.com/nnthanh101/terraform-aws) ↔ local development via `git pull --rebase` / `git push`.

---

## [2.2.2](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.2.1...terraform-aws-v2.2.2) (2026-03-14)


### Bug Fixes

* sync CHANGELOG and VERSION with v2.2.1 release → triggers v2.2.2 ([87bf2dd](https://github.com/nnthanh101/terraform-aws/commit/87bf2dd6bf9164d67bcfeb6c8df121225f48d9dd))

## [2.2.1](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.2.0...terraform-aws-v2.2.1) (2026-03-14)

### Business Value

**$180/mo production web stack** — 5 new modules complete the xOps BC1 6-Layer Sovereign Stack. HITL runs `terraform apply` once and gets HTTPS + CDN + WAF + persistent storage + encryption. No manual console clicks.

### New Modules

| Module | Business Value | Cost |
|--------|---------------|------|
| **cloudfront** | Global <50ms latency, 60-80% origin cost reduction, AWS Shield Standard (free DDoS) | $0-15/mo |
| **waf** | OWASP Top 10 protection, bot mitigation, rate limiting — regulatory checkbox for APRA CPS 234 | $5-20/mo |
| **alb** | Cross-AZ high availability, health checks, blue/green deployment ready — zero-downtime deploys | $20-40/mo |
| **efs** | Chat history survives container restarts, encrypted at rest via KMS, shared across tasks | $6/mo |
| **kms** | Customer-managed encryption keys, automatic annual rotation, data sovereignty compliance | $1/mo per key |

### Developer Experience

- **Local CI/CD with `act`** — validate + lint + test without pushing. Catches broken workflows before they waste CI minutes.
- **Node.js 24 CI upgrade** — all 9 GitHub Actions workflows upgraded from `@v4` to `@v5` (`actions/checkout`, `upload-artifact`). 42 replacements across workflows.

---

## [2.2.0](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.1.0...terraform-aws-v2.2.0) (2026-03-13)

### Business Value

**Zero-touch registry publishing** — push a conventional commit, release-please creates a PR, HITL merges, modules appear in TFC Private Registry automatically. Eliminates manual publish steps that caused SIC-001 "no healthy versions" incident.

### What Changed

- **Docker-first CI/CD** — all jobs run in `nnthanh101/terraform:2.6.0` (SHA-pinned). No "works on my machine" — same container locally and in GitHub Actions.
- **Registry auto-sync** — `registry-publish.yml` iterates all 12 module tags, not just IAM IC. One workflow for all modules.
- **Checkov APRA + FOCUS tag compliance** — security scanning enforces `CostCenter`, `DataClassification`, `Environment` tags at plan time, not after deployment.
- **Release-please v4 monorepo fix** — output keys use `modules/X--tag_name` format (was `X--tag_name`, causing silent publish failures).

---

## [2.1.0](https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.0.0...terraform-aws-v2.1.0) (2026-03-13)

### Business Value

**Enterprise SSO in 15 minutes** — 4-tier landing zone (PlatformTeam, PowerUsers, AuditTeam, SecurityTeam) from a single YAML file. Auditors review YAML, not HCL. APRA CPS 234 compliant out of the box. ([#46](https://github.com/nnthanh101/terraform-aws/issues/46))

### What Consumers Get

- **One version, 12 modules** — `source = "app.terraform.io/oceansoft/sso/aws" version = "~> 2.1"` works for any of the 12 modules. Pin once, use everywhere.
- **YAML-driven permission sets** — non-engineers can review and approve IAM policies. Separation of config (YAML) from logic (HCL).
- **One-click publish pipeline** — push tag → validate → lint → Tier-1 test → publish → verify ingestion. No manual steps.

### 12 Building-Block Modules

| Module | What It Solves | Who Benefits |
|--------|---------------|--------------|
| **sso** | Centralized login for 50+ AWS accounts | Platform teams, auditors |
| **ecs** | Serverless containers — pay per second, auto-scale to zero | Application teams |
| **web** | Production web stack in one module (ALB + TLS 1.3 + FOCUS tags) | Full-stack teams |
| **acm** | Zero-cost auto-renewing TLS certificates, wildcard domains | Security teams |
| **alb** | Cross-AZ load balancing with health checks | SRE teams |
| **cloudfront** | Global CDN with DDoS protection | Performance teams |
| **efs** | Encrypted persistent storage for containers | Data teams |
| **kms** | Customer-managed encryption with auto-rotation | Compliance teams |
| **s3** | 11 9s durable storage with lifecycle cost optimization | All teams |
| **sftp** | Managed SFTP — no server to patch, audit trail included | Integration teams |
| **vpc** | Network isolation with public/private/database subnets | Network teams |
| **waf** | OWASP Top 10 + bot protection for CloudFront and ALB | Security teams |

### Under the Hood

- Docker-first: `nnthanh101/terraform:2.6.0` SHA-pinned container
- Checkov: 52 consumer-decision skips (building blocks expose variables, consumers decide security posture)
- WAF deprecated `lookup()` calls updated to 3-arg form (no consumer action needed)
- docs-sync race condition fixed (`max-parallel: 1`)

---

## [2.0.0](https://github.com/nnthanh101/terraform-aws/releases/tag/terraform-aws-v2.0.0) (2026-03-05)

### Business Value

**The unified versioning epoch.** Before v2.0.0, each module had its own version (sso v1.2.1, ecs v1.0.0, web v1.0.2) — consumers tracked 12 different versions. Now: one `terraform-aws-vX.Y.Z` tag spans all 12 modules. Pin once, upgrade once.

### What Changed

- **Single semver for all modules** — ADR-026 decision. `terraform >= 1.11.0`, `aws >= 6.28, < 7.0` pinned across all 12.
- **Compliance out-of-the-box** — Apache 2.0 license, APRA CPS 234 tagging, FOCUS 1.2+ cost tags, upstream attribution in NOTICE.txt.
- **release-please automation** — conventional commits drive version bumps. `feat:` = minor, `fix:` = patch, `!` = major.

### Breaking Changes

- Per-module version tags (`iam-identity-center/v1.x.x`, `ecs/v1.x.x`, `fullstack-web/v1.x.x`) are frozen. All future releases use `terraform-aws-vX.Y.Z`.

---

## [1.1.0](https://github.com/nnthanh101/terraform-aws/compare/v1.0.0...v1.1.0) (2026-02-28)

### Business Value

**TFC Registry actually works** — root wrapper module fixes SIC-001 "no healthy versions" error. Consumers can now `terraform init` against the private registry without workarounds.

### What Changed

- **Production multi-account example** — 4-account Landing Zone (Management, Security-Audit, Shared-Services, Workloads) with ABAC and permission boundaries. Copy-paste ready.
- **VERSION alignment** — root and `modules/sso/` versions synced (ADR-015). Eliminates registry confusion.
- **18 Tier-1 snapshot tests** — all passing. <3 seconds, zero cloud cost.

---

## [1.0.0](https://github.com/nnthanh101/terraform-aws/releases/tag/v1.0.0) (2026-02-26)

### Business Value

**IAM Identity Center as code** — enterprise SSO with YAML configuration layer. Auditors review permission sets in YAML, not HCL. Derived from `aws-ia/terraform-aws-sso` v1.0.4 (Apache-2.0) with APRA CPS 234 compliance layer.

### What Consumers Get

- 8 examples — single-account, multi-account, ABAC, permission boundary patterns
- 8 Tier-1 snapshot tests — validate before apply, zero cloud cost
- CI pipeline — validate → lint → legal → governance → test gates
- Registry publication workflow — tag-driven, automated

### Architectural Decisions

ADR-001 through ADR-007 established: module structure, naming conventions, testing strategy, registry publishing, compliance tagging, upstream attribution, and CI/CD pipeline design.

---

## Module Version History (Pre-Unified)

Legacy per-module tags (frozen at v2.0.0 — no new releases on these tag lines):

| Module | Last Per-Module Tag | Now Covered By |
|--------|-------------------|----------------|
| iam-identity-center | v1.3.0 | `terraform-aws-v2.x.x` |
| ecs | v1.1.0 | `terraform-aws-v2.x.x` |
| fullstack-web | v1.0.2 | `terraform-aws-v2.x.x` |

[2.2.1]: https://github.com/nnthanh101/terraform-aws/compare/terraform-aws-v2.2.0...terraform-aws-v2.2.2
