# Changelog — oceansoft/ecs/aws

All notable changes to this module are documented in this file.
Release-please auto-generates `modules/ecs/CHANGELOG.md` for git-level history.
This file provides **business-context** for stakeholders and auditors.

Upstream provenance: [UPSTREAM-CHANGELOG.md](UPSTREAM-CHANGELOG.md) (terraform-aws-modules/terraform-aws-ecs v7.3.1).

---

## [1.0.0] — 2026-03-02

### Business Impact

- **Cost Visibility**: `default_tags` variable enforces FOCUS 1.2+ tag keys (`CostCenter`, `DataClassification`) across every ECS resource — enables FinOps showback from day one without manual tagging discipline
- **Regulatory Compliance**: APRA CPS 234 check block validates tag presence at `terraform plan` time — audit findings caught pre-deployment, not post-incident
- **Time-to-Value**: Wrapper pattern consumes upstream terraform-aws-modules/ecs v7.3.1 via `source` — enterprise teams get production-grade ECS (Fargate, EC2, Express, Managed Instances) without building from scratch
- **Risk Reduction**: 5 Tier 1 snapshot tests (cluster defaults, Fargate capacity, service for_each, tag propagation, create-disabled) run in CI at $0 cost — catches regressions before any AWS spend
- **Legal Exposure**: Apache 2.0 Section 4(b) compliance across all 64 .tf files with copyright + upstream attribution headers — eliminates license violation risk

### Technical Excellence

- **ADR-003 Enforcement**: `required_version >= 1.11.0`, provider `>= 6.28, < 7.0` across 16 versions.tf files — prevents silent drift to unsupported Terraform/provider versions
- **provider_meta Removal**: Stripped 9 upstream `provider_meta "aws"` user-agent blocks — clean provider configuration, no telemetry leakage
- **4 Sub-modules**: cluster, service, container-definition, express-service — separation of concerns with independent versioning capability
- **6 Examples**: complete, container-definition, ec2-autoscaling, express-service, fargate, managed-instances — validated consumer patterns covering all launch types
- **Wrapper Pattern**: Root module delegates to sub-modules via `source = "./modules/*"` — single registry entry `oceansoft/ecs/aws` exposes full ECS platform
- **CI Integration**: PR title validation (conventional commits), Trivy security scan, legal audit — all in existing workflows, no new workflow files (KISS)
- **CODEOWNERS**: Platform engineers + compliance reviewers gated on module paths, tests, examples, and legal files

### Migration Notes

- New `default_tags` variable defaults to `{}` — existing consumers unaffected (zero breaking changes)
- Upstream `provider_meta` blocks removed — if you depended on upstream user-agent telemetry, this is no longer sent
- Sub-module `versions.tf` constraints tightened — consumers on Terraform < 1.11.0 must upgrade

### Upstream Attribution

Derived from [terraform-aws-modules/terraform-aws-ecs](https://github.com/terraform-aws-modules/terraform-aws-ecs) v7.3.1 (Apache-2.0).
See [NOTICE.txt](../NOTICE.txt) and [UPSTREAM-CHANGELOG.md](UPSTREAM-CHANGELOG.md) for full provenance.
