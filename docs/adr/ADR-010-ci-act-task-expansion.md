# ADR-010: ci:act Task — Full Pipeline Expansion + PATH Injection

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, Infrastructure Engineer
- **Migrated from**: ADR-ACT-002 + ADR-ACT-003 (consolidated — both govern the ci:act Taskfile task)

## What

Two related decisions governing the `ci:act` Taskfile task:

1. Expand `ci:act` from `--job validate` (1 job) to all 6 jobs in `ci.yml` (validate matrix, legal, governance, test, lock-verify, security)
2. Preserve `export PATH="/home/os/.local/bin:${PATH}"` in all act invocations (act binary lives in non-standard path inside devcontainer)

## Why

### Full pipeline expansion (ACT-002)

Current `ci:act` runs only `--job validate` on `ci.yml`. This leaves 5 jobs untested locally, reducing confidence in pre-push validation. Removing `--job validate` makes act execute the full 6-job pipeline with the same job dependency order (`needs:`) as GitHub Actions.

### PATH injection (ACT-003)

act binary is installed at `/home/os/.local/bin/act` inside `nnthanh101/terraform:2.6.0`. Without the PATH export, `command not found: act` fails silently inside the `_exec` helper. The current `ci:act` task already exports PATH — this must be preserved in any refactoring.

## Who

- **Infrastructure Engineer**: Updates `Taskfile.yml` ci:act task
- **Cloud Architect**: Design decision (this ADR)

## When

Sprint 2, Phase 1.

## Where

`Taskfile.yml` `ci:act` task definition.

## How

```bash
# ci:act task target
export PATH="/home/os/.local/bin:${PATH}"
act push \
  --workflows .github/workflows/ci.yml \
  --platform ubuntu-latest=nnthanh101/terraform:2.6.0@sha256:3e159226f661171fb26baa360af7ddc0809076376a3cd6c37b8614186770f16a \
  --artifact-server-path tmp/terraform-aws/ci-act/artifacts \
  --rm \
  --env CI=true \
  2>&1 | tee tmp/terraform-aws/ci-act/act-$(date +%Y-%m-%d).log
```

## Consequences

### Benefits
1. Local CI gate covers all 6 jobs — no surprises at GitHub Actions execution
2. Log written to `tmp/terraform-aws/ci-act/` provides evidence for ADLC audit trail
3. PATH injection is explicit and documented — safe to refactor ci:act in future

### Tradeoffs
1. Full 6-job run is slower than single-job validate (target: < 120s)

## Related ADRs

- [ADR-009](./ADR-009-act-actrc-platform-mapping.md): .actrc prerequisite for this task
- [ADR-011](./ADR-011-act-advisory-dry-run.md): advisory dry-run for other workflows

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
