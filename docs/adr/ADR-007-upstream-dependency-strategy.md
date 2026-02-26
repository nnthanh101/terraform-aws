# ADR-007: Upstream Dependency Strategy — aws-ia Fork + Rebrand

- **Status**: Accepted
- **Date**: 2026-02-26
- **Deciders**: HITL/Manager, Product Owner, Cloud Architect
- **HITL Decision**: HITL-004

## What

Module strategy for Identity Center: fork `aws-ia/terraform-aws-iam-identity-center` (Apache-2.0), strip AWSCC provider, add YAML config API, rebrand to `nnthanh101/oceansoft.io`.

## Why

| Factor | aws-samples | aws-ia (fork) | Custom from scratch |
|--------|-------------|---------------|---------------------|
| Outputs | `{}` permanently | Full ARNs, IDs | Full (must build) |
| ABAC/JIT/SCIM | Impossible | Built-in | Must implement |
| YAML audit (APRA CPS 234) | Yes | Add via fork | Must implement |
| Maintenance | Low (18 LOC) | Medium (fork) | High (~370+ LOC) |
| License | MIT-0 | Apache-2.0 | Apache-2.0 |
| Registry credibility | Low (no outputs) | High | High |
| Composition | Blocked | Enabled | Enabled |

**Decision driver**: `permission_set_arns = {}` in aws-samples is permanent — blocks downstream module composition and Registry publication. Custom from scratch reinvents what aws-ia already provides under Apache-2.0.

## Who

- **HITL/Manager**: Approved fork+rebrand strategy
- **Cloud Architect**: Evaluates aws-ia module, designs AWSCC removal
- **Infrastructure Engineer**: Executes fork, strips AWSCC, adds YAML config

## When

| Sprint | Action |
|--------|--------|
| Sprint 1 | Fork+rebrand DELIVERED — 337 LOC, 14 resource types, YAML config layer |
| Sprint 2 | ABAC, JIT, SCIM extensions on forked module |
| Sprint 3+ | Multi-region, cross-account federation patterns |
| v1.0.0 | Registry publish at `app.terraform.io/app/oceansoft/` |

## Where

- Fork source: `github.com/aws-ia/terraform-aws-iam-identity-center`
- Target: `oceansoft/iam-identity-center/aws` (Registry: `app.terraform.io/app/oceansoft/`)
- Region: us-east-1 (Identity Center global service)
- Config: `modules/iam-identity-center/examples/*.yaml` (YAML audit trail retained)

## How

1. Clone `aws-ia/terraform-aws-iam-identity-center` to `/tmp/aws-ia-identity-center` (HITL)
2. Strip AWSCC provider dependency (replace with `aws_ssoadmin_*` resources)
3. Add `yamldecode()` config API for APRA CPS 234 compliance
4. Retain full outputs (ARNs, IDs) for downstream composition
5. Rebrand to `nnthanh101` namespace, publish to Terraform Registry
6. Side-by-side test with Sprint 1 YAML configs

## Clone + Rebrand Pattern (Sprint 1 — Delivered)

The IAM Identity Center module at `modules/iam-identity-center/` is a **clone + rebrand**
of `aws-ia/terraform-aws-iam-identity-center` v1.0.4. There is no `module { source = "..." }`
block — all resources are defined directly.

### Resource Types (14)

| File | Resources |
|------|-----------|
| `main.tf` | `aws_identitystore_group`, `aws_identitystore_user`, `aws_identitystore_group_membership`, `aws_ssoadmin_permission_set`, `aws_ssoadmin_managed_policy_attachment`, `aws_ssoadmin_customer_managed_policy_attachment`, `aws_ssoadmin_permission_set_inline_policy`, `aws_ssoadmin_permissions_boundary_attachment`, `aws_ssoadmin_account_assignment`, `aws_ssoadmin_application`, `aws_ssoadmin_application_assignment`, `aws_ssoadmin_trusted_token_issuer` |
| `data.tf` | `aws_ssoadmin_instances` (data), `aws_identitystore_group` (data), `aws_identitystore_user` (data), `aws_ssoadmin_permission_set` (data) |

### Architecture

- **`locals.tf`** (224 LOC): Transforms variable inputs via `flatten()` operations for
  `for_each` iteration. YAML config layer via `yamldecode()` (ADR-008).
- **`data.tf`**: Fetches SSO instance, existing groups/users, existing permission sets.
- **`variables.tf`**: Full SCIM user profile (30+ attributes), permission sets
  (AWS managed, customer managed, inline, boundary), account assignments, applications,
  ABAC attributes.
- **`outputs.tf`**: 10 outputs — ARNs, IDs, assignment maps for downstream composition.

### Apache 2.0 Compliance

- Copyright headers on all `.tf` files
- `LICENSE` file (Apache License 2.0)
- `NOTICE.txt` with attribution to upstream `aws-ia` (Section 4d)
- CODEOWNERS at `.github/CODEOWNERS` with per-path review rules

## Sustainability (2026-2030)

| Control | Implementation |
|---------|---------------|
| Lock file | `.terraform.lock.hcl` committed |
| Version pin | `~> 1.0` on forked module |
| Annual review | January: check aws-ia upstream for backports |
| License | Apache-2.0 — attribution required (NOTICE file) |

## Consequences

- **Positive**: Real outputs enable composition, Registry publish is credible, ABAC/JIT/SCIM path exists
- **Positive**: YAML config API preserved for auditor review (APRA CPS 234 Para 37)
- **Negative**: Fork maintenance burden (must track upstream aws-ia changes)
- **Mitigated**: Apache-2.0 allows free fork; aws-ia is feature-complete baseline
