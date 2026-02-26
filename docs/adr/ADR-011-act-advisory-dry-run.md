# ADR-011: act Advisory Dry-Run + Artifact Server for Non-CI Workflows

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, Infrastructure Engineer
- **Migrated from**: ADR-ACT-004 + ADR-ACT-005 (consolidated — both govern act behavior for workflows beyond ci.yml)

## What

Two related decisions for act validation of the 4 workflows that cannot fully execute locally:

1. Use `act --dry-run` for `infracost.yml`, `docs-sync.yml`, `provider-upgrade.yml`, `registry-publish.yml` to validate YAML structure without executing steps that require secrets or write tokens
2. Configure `--artifact-server-path` in `.actrc` so `actions/upload-artifact@v4` steps succeed when ci.yml runs locally

## Why

### Advisory dry-run (ACT-004)

| Workflow | Blocker | act Mode |
|----------|---------|----------|
| `infracost.yml` | `INFRACOST_API_KEY` secret + pip install on bare runner | `--dry-run` |
| `docs-sync.yml` | terraform-docs/gh-actions needs action resolution | `--dry-run --action-offline-mode` |
| `provider-upgrade.yml` | `open-pr` job needs GITHUB_TOKEN write scope | `--dry-run` for `upgrade-locks` job only |
| `registry-publish.yml` | Tag context + `gh release create` + TFC VCS webhook | `--dry-run --event-path` fake tag event |

Dry-run validates YAML syntax and job dependency graph without executing steps.

### Artifact server (ACT-005)

Without `--artifact-server-path`, `actions/upload-artifact@v4` steps in governance and legal jobs either fail silently or error, masking real failures. The path `tmp/terraform-aws/ci-act/artifacts` aligns with the evidence directory convention.

## How

```bash
# Validate workflow YAML structure without execution
act push --dry-run --workflows .github/workflows/registry-publish.yml
act pull_request --dry-run --workflows .github/workflows/infracost.yml
act schedule --dry-run --workflows .github/workflows/provider-upgrade.yml
act push --dry-run --workflows .github/workflows/docs-sync.yml
```

Artifact server is configured in `.actrc` (see ADR-009) — no per-invocation flag needed.

## Consequences

### Benefits
1. All 5 workflows pass structural validation locally — satisfies R-P1-02 (all workflows tested)
2. Artifact server prevents silent upload failures in ci.yml governance jobs

### Tradeoffs
1. Dry-run does not catch runtime failures in infracost/registry workflows — accepted as out-of-scope for local validation

## Related ADRs

- [ADR-009](./ADR-009-act-actrc-platform-mapping.md): .actrc (artifact-server-path configured here)
- [ADR-010](./ADR-010-ci-act-task-expansion.md): full ci.yml execution (complements dry-run scope)

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
