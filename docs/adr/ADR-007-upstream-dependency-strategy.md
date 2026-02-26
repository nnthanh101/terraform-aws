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
| Sprint 1 | aws-samples wrapper (current — 18 LOC, YAML audit) |
| Sprint 2 | Fork aws-ia, strip AWSCC, add YAML config, rebrand |
| Sprint 3+ | ABAC, JIT, SCIM extensions on forked module |
| v1.0 | Registry publish with real ARN outputs |

## Where

- Fork source: `github.com/aws-ia/terraform-aws-iam-identity-center`
- Target: `nnthanh101/oceansoft.io` (Registry: `nnthanh101/terraform-aws/aws`)
- Region: us-east-1 (Identity Center global service)
- Config: `modules/identity-center/configs/*.yml` (YAML audit trail retained)

## How

1. Clone `aws-ia/terraform-aws-iam-identity-center` to `/tmp/aws-ia-identity-center` (HITL)
2. Strip AWSCC provider dependency (replace with `aws_ssoadmin_*` resources)
3. Add `yamldecode()` config API for APRA CPS 234 compliance
4. Retain full outputs (ARNs, IDs) for downstream composition
5. Rebrand to `nnthanh101` namespace, publish to Terraform Registry
6. Side-by-side test with Sprint 1 YAML configs

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
