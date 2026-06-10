---
title: "ADR-028: Parallel 2-Account Topology with IAM Identity Center + Profile-Only Configuration"
description: Decision to build parallel workload and management (Identity Center) accounts in parallel at zero cost (plan/validate); profile-only environment configuration with runtime account discovery via AWS APIs; legacy Terraform module consolidation into canonical submodule in waves; LLM-Docs engine applied to both this repository and private companion documentation repository.
sidebar_position: 28
tags: [adr, infrastructure, multi-account, identity-center, profile-config, llm-docs, terraform]
source_refs:
  - path: "terraform-aws project coordination logs (see companion private documentation)"
    last_compiled: "2026-06-10"
last_compiled: "2026-06-10T00:00:00Z"
---

import { Note } from '@site/src/components/Note';

# ADR-028: Parallel 2-Account Topology with IAM Identity Center + Profile-Only Configuration

**Status**: Accepted
**Date**: 2026-06-10
**Version**: 0.1.0
**Scope**: Architectural decisions for parallel 2-account topology (workload + management); profile-only configuration pattern; legacy module consolidation strategy; LLM-Docs compilation.

---

## Context

This repository (`terraform-aws`) is a publicly available, MIT-licensed collection of reusable AWS infrastructure modules. It is consumed as a git submodule by private product repositories that deploy infrastructure to multiple AWS accounts.

**Key facts**:
- **Terraform version**: ≥1.11.0
- **AWS provider**: ≥6.28, <7.0
- **Current modules**: 12 (sso, ecs, web, alb, acm, cloudfront, s3, vpc, efs, kms, waf, sftp)
- **Module structure**: `accounts/<account-type>/` for account-scoped configs (e.g., `accounts/management-account/` for Identity Center hub)
- **State management**: S3 native locking (no DynamoDB, per ADR-006)
- **Deployment pattern**: Profile-based authentication; account identifiers derived at runtime

**Architectural question**: How should multiple AWS accounts (workload + management/Identity Center) be represented in the module structure, given that:
- Both account types consume the same submodule set?
- Account identifiers must remain derivable, not hardcoded?
- The module library serves both public (MIT) and private deployment contexts?

---

## Decision

**D1 — Parallel Account Topology (Lean 2-Account Baseline)**: This submodule supports a **lean 2-account topology** as the baseline:
1. **Management account** — Organizations data source, IAM Identity Center hub (may require post-deployment enablement), permission sets, account assignments, GitHub OIDC provider
2. **Workload account** — Infrastructure for customer-facing platform (VPC, container orchestration, databases, etc.)

Both accounts are **planned and validated in parallel** against `accounts/<account-type>/` roots. Full Landing Zone OUs (audit/network/security accounts) are deferred; the re-entry condition is documented and binding.

**Critical guardrail**: When deploying to a new landing zone, ensure you are NOT reusing an IAM Identity Center instance from a different AWS landing zone or tenant. Each organization should enable its own Identity Center instance within its own AWS Organization home region.

**Rationale**: Accounts are operationally independent (disjoint Terraform file paths). Parallelism unblocks faster validation cycles without added complexity. The `modules/sso` module assumes an existing Identity Center instance via data source and does not create one; enablement is a one-time manual step in the management console before Terraform planning.

---

**D2 — Profile-Only Configuration; Zero Hardcoded Identifiers**: Consumers of this submodule configure accounts using **AWS profile names only**. Account identifiers are **derived at runtime** using:
- AWS API: `aws sts get-caller-identity` (returns `Account` JSON field)
- AWS CLI: `aws organizations list-accounts --profile <profile>`
- Terraform: `data.aws_caller_identity` + `data.aws_organizations_*` data sources

**Environment variables carry only**:
- `AWS_PROFILE_<ACCOUNT_TYPE>=<profile-name>` (e.g., `AWS_PROFILE_WORKLOAD=<your-workload-profile>`)
- `AWS_REGION=<region-per-deployment>`
- `AWS_DEFAULT_REGION=<region-per-deployment>`
- `IDENTITY_CENTER_REGION=<region-where-identity-center-is-active>`

**No hardcoded account IDs, no hardcoded account emails, no hardcoded AWS account numbers**.

**Rationale**: Account identifiers are runtime-derivable from the profile. Hardcoding them couples the module to specific customer environments and creates enumeration leaks. Profile-only config is the minimal, reusable surface.

---

**D3 — Legacy Terraform Module Consolidation into Canonical Submodule**: This submodule consolidates reusable infrastructure patterns into a single, versioned, registry-published module library. Legacy module mirrors that exist in private repositories are migrated into this canonical location following a **salvage-first discipline**:

- **Salvage**: Read legacy source code; extract resource types, variable names, output names.
- **Modernize**: Upgrade Terraform version constraint to ≥1.11; AWS provider to ≥6.28, <7.0. Remove deprecated arguments.
- **NOTICE + derived-module header**: Add NOTICE.txt; add header in main.tf citing the original source and modernization.
- **Tests**: Add `.tftest.hcl` snapshot tests asserting output structure.
- **Docs**: Auto-generate README via `terraform-docs`.
- **Release**: Add per-module entry to `release-please` manifest.
- **Security**: Run checkov and tflint; resolve HIGH/CRITICAL findings before merge.

Each wave of migration produces durable evidence (file paths, test results, checkov scans). Legacy sources remain available for reference during the migration; they are not deleted until all consumers are migrated forward.

**Rationale**: Single source of truth for module logic; future consumers compose proven patterns (DRY, rung 3). No split-brain code maintenance.

---

**D4 — LLM-Docs Engine Applied; Public Output Only**: This repository's documentation is compiled from Terraform source files (HCL, tftest.hcl, variable blocks, output blocks) using an automated documentation generation pipeline. The compiled output includes:
- Module README files (auto-generated via `terraform-docs`)
- Account configuration guides
- A repository-level `llms.txt` index enabling AI agent discovery

The **compilation engine itself is not committed to this repository**. Only the compiled artifacts (READMEs, `llms.txt`) are version-controlled and published. The engine is consumed at CI build time via authenticated access to a private companion repository, following a sparse-checkout pattern that prevents engine source code from leaking into the public tree.

**Rationale**: Agents and humans read the same SSOT (compiled module documentation). Docs compile from code, so they stay in sync with implementation and cannot drift. AI discoverability is enabled via machine-readable `llms.txt`. The engine implementation is proprietary (not part of the public MIT license); only the output is public.

---

## Rationale

1. **2-Account baseline covers MVP needs**: Workload and management (Identity Center) are the minimal viable accounts. Additional accounts (audit, network, security) are deferred until the re-entry condition is met.

2. **Parallelism compresses deployment timeline**: Both account roots can be planned/validated in the same CI run, removing sequential dependencies.

3. **Profile-only config is portable**: Any organization can deploy these modules by running `aws sso login --profile <name>`. No customer-specific secrets or account IDs are baked into code.

4. **Single module library reduces maintenance**: Migrating legacy patterns into the canonical submodule unifies the reference implementation. Future operators reuse tested patterns instead of re-authoring.

5. **Compiled documentation stays current**: Auto-generated READMEs and `llms.txt` index track HCL changes automatically; no separate doc-update tickets needed.

---

## Alternatives Considered

| Alternative | Rejected Because |
|-------------|-----------------|
| **(a) Single account only (no management account in module scope)** | Management account (Identity Center hub) is a first-class workload account in the 2-account topology; excluding it from the module library means reimplementing IAM, permission sets, and account assignment logic in every consumer |
| **(b) Hardcode account IDs/emails in module variables** | Couples modules to specific customers; violates multi-tenancy principle; creates enumeration leaks if public repo is mirrored; increases drift/rotation burden |
| **(c) Keep legacy modules in a separate repository** | Same-module logic maintained in two places = `LEGACY_MIRROR_DRIFT` anti-pattern; future consumers read inconsistent HCL; module maintenance burden multiplies |
| **(d) Hand-maintained documentation** | Docs fall out of sync with HCL as modules evolve; search/discovery is manual; AI agents cannot programmatically extract module capabilities |

---

## Consequences

### Positive
- **Modular, reusable infrastructure**: Consumers across different organizations deploy using the same tested, versioned modules.
- **Clear account topology**: `accounts/management-account/` and `accounts/<workload>/` structure is self-documenting.
- **No secret sprawl**: Profile-only config eliminates hardcoded credentials and account enumeration.
- **Automatic documentation**: Module README files and discovery index regenerate on every module change; docs never lag behind code.
- **Consolidated maintenance**: Single module library reduces version-management overhead; security patches apply once, to all consumers.

### Negative / Residual Risk
- **Profile name must exist**: Consumers must pre-configure AWS profiles with specific names in their local AWS config. **Mitigated by**: Documentation (README, deployment guide) specifies profile names and setup steps clearly.
- **Account metadata lookup latency**: Using `data.aws_caller_identity` and `data.aws_organizations_*` to derive account info adds small Terraform plan overhead. **Mitigated by**: Negligible in practice (one API call per plan); caching via Terraform state reduces subsequent plan times.
- **Legacy module migration effort**: Consolidating multiple legacy modules into canonical versions requires per-module salvage, modernization, testing, and documentation work. **Mitigated by**: Standardized migration recipe (documented in private companion repo); per-module effort is bounded; reuse of recipe across waves.

### Unchanged
- Module versioning strategy (ADR-002 — per-module semver via `release-please`)
- State backend design (ADR-006 — S3 native locking, no DynamoDB)
- Provider constraints (ADR-003 — TF ≥1.11, AWS provider ≥6.28, <7.0)
- Testing tiers (ADR-004 — snapshot/LocalStack/Terratest)

---

## Amendment (2026-06-10)

**Clarification on Identity Center deployment**: When deploying this topology to a new AWS Organization, IAM Identity Center may need to be enabled as a one-time setup step in the AWS Management Console. The `modules/sso` module assumes an existing Identity Center instance is available (via `data "aws_ssoadmin_instances"`) and manages the full post-enablement lifecycle (permission sets, group assignments, account assignments). It does not create the instance itself.

Consumers must NOT reuse an Identity Center start URL or instance from a different AWS landing zone or organizational tenant — this is a critical security boundary. Each organization maintains its own isolated Identity Center instance.

---

## Deployment Pattern

### Consumer Workflow

```bash
# Step 1: Authenticate to AWS accounts
aws sso login --profile management
aws sso login --profile workload

# Step 2: Export environment variables (profile names, region)
export AWS_PROFILE_MANAGEMENT=management
export AWS_PROFILE_WORKLOAD=workload
export AWS_REGION=${YOUR_REGION}
export IDENTITY_CENTER_REGION=${YOUR_IDENTITY_CENTER_REGION}

# Step 3: Plan infrastructure for both accounts (in parallel)
terraform -chdir=accounts/management-account plan
terraform -chdir=accounts/workload plan

# Step 4: Validate
terraform -chdir=accounts/management-account validate
terraform -chdir=accounts/workload validate
```

**Profile derivation at runtime** (example):

```hcl
# Terraform: accounts/workload/main.tf
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
  # Derived at plan time; no hardcoded 12-digit ID
}

# Terraform: accounts/workload/providers.tf
provider "aws" {
  region  = var.region
  profile = var.profile  # Set via TF_VAR_profile=workload or .tfvars
}
```

---

## Registry Publishing

Modules are versioned and published to the public Terraform Registry (`registry.terraform.io/`) under the MIT license. Each module carries:
- `LICENSE` (Apache 2.0 or MIT as applicable)
- `NOTICE.txt` (if derived from upstream, cites source and license)
- `README.md` (auto-generated via `terraform-docs`)
- `.tftest.hcl` (test assertions)
- `versions.tf` (Terraform and provider constraints)

---

## References

- **This repo**: `github.com/nnthanh101/terraform-aws` (PUBLIC, MIT)
- **Profile authentication**: AWS documentation — "Using temporary credentials with AWS SSO"
- **Architecture pattern**: Multi-account, identity-center-managed, profile-based AWS deployments
- **Companion documentation**: Private repository with detailed migration register, per-module 5W1H analysis, and LLM-Docs engine implementation (linked in private internal docs only)
- **Related ADRs** (in private companion):
  - ADR-006 — S3 native state locking (this repo adopts it)
  - ADR-023 — Derived-module pattern (migration recipe)
  - ADR-024 — Composition layer (modules/web wiring pattern)

---

## Questions for Consumers

**Q: How do I know which profile to use?**
A: Documentation (README, deployment guide) specifies profile setup steps. Profile name is a deployment parameter, not hardcoded. Your ops team configures profiles once; all Terraform runs use them.

**Q: Can I hardcode my account ID in the module?**
A: No. This prevents code reuse and leaks account enumeration. Derive account ID from `data.aws_caller_identity` or profile lookup instead.

**Q: What if I'm deploying to a new account?**
A: Create a new AWS profile in your local AWS config (`aws configure sso --profile <new-profile>`), then set `AWS_PROFILE_WORKLOAD=<new-profile>`. Terraform derives the rest.

**Q: Is the documentation kept up-to-date?**
A: Yes. Module READMEs and the `llms.txt` index are auto-generated from HCL at every CI run. Documentation reflects the current state of the modules.
