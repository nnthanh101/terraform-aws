# ADR-014: Priority Examples for Cross-Validation

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, QA Engineer
- **Migrated from**: ADR-XVAL-004

## What

Define the priority order for example-level cross-validation of the `modules/iam-identity-center` module, distinct from the full `terraform validate` sweep that covers all 8 examples.

## Why

Not all examples exercise the same code paths. Prioritizing by code branch coverage maximizes bug detection per CI minute.

## Decisions

| Priority | Example | Code Path | Reason |
|----------|---------|-----------|--------|
| P1 | `tests/snapshot/01_mandatory.tftest.hcl` | All variables, all resource types | Baseline schema — catches variable contract breaks |
| P2 | `examples/create-users-and-groups` | Create path (CRUD) | Most common use case, exercises `identitystore_*` + `ssoadmin_*` |
| P3 | `examples/existing-users-and-groups` | Data source (read-only) path | Different code branch — exercises `data.tf` fetchers |

Remaining 5 examples (ABAC, applications, Google Workspace, etc.) are covered by `terraform validate` in the `build:validate` sweep. Full Tier 3 integration tests against AWS are a HITL-gated operation.

## Consequences

### Benefits
1. P1 snapshot test is free ($0 AWS cost, 2-3s) and catches variable schema regressions immediately
2. P2 and P3 together cover the two primary code branches (write vs read-only)

### Tradeoffs
1. ABAC and application examples are not in Tier 1/2 priority — accepted given cost and complexity

## Related ADRs

- [ADR-013](./ADR-013-build-validate-scope-expansion.md): validate scope (all examples get `terraform validate`)
- [ADR-004](./ADR-004-three-tier-testing.md): 3-tier testing framework

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
