# ADR-018: Registry Publish Pre-Flight Checklist + HITL Execution Sequence

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, HITL/Manager
- **Migrated from**: ADR-REG-004
- **HITL Decision**: HITL-004 (publish gate)

## What

Define the mandatory pre-flight checklist that must pass before HITL creates the `v1.0.4` git tag, and the execution sequence for the Registry publish pipeline.

## Why

Registry publish is irreversible without a new version. A failed publish (tag exists but no release, or broken module) creates a gap in the version history that consumers may attempt to pin to. The pre-flight checklist ensures all automated gates pass before HITL executes the one action agents cannot perform (git tag).

## Who

- **Infrastructure Engineer**: Executes automated checks in the pre-flight list
- **HITL/Manager**: Verifies checklist completion, creates git tag, monitors pipeline

## When

After ADR-015 (VERSION), ADR-016 (CHANGELOG), and ADR-017 (SUBMODULE_PAT) are complete.

## How

### Pre-Flight Checklist (all must PASS before HITL creates tag)

```
[ ] task ci:quick            -- validate + lint + legal: all PASS
[ ] task test:tier1          -- all 8 snapshot tests: PASS
[ ] task govern:legal        -- Apache 2.0 compliance: PASS
[ ] Root VERSION = 1.0.4     -- file updated (ADR-015)
[ ] CHANGELOG.md updated     -- v1.0.1 through v1.0.4 documented (ADR-016)
[ ] registry-publish.yml     -- SUBMODULE_PAT checkout fix applied (ADR-017)
[ ] act push --dry-run       -- registry-publish.yml YAML validates: PASS
```

### Pipeline Architecture

```
Tag v1.0.4 pushed (HITL)
       |
       v
[validate] task ci:quick (fmt + lint + legal)
  Container: nnthanh101/terraform:2.6.0, --user 0
  PASS -> continues | FAIL -> pipeline stops
       |
       v
[test] needs: [validate]
  task test:tier1 (8 snapshot tests, $0 cost)
  Container: nnthanh101/terraform:2.6.0, --user 0
  PASS -> artifact uploaded | FAIL -> pipeline stops
       |
       v
[release] needs: [test]
  gh release create v1.0.4 --generate-notes
  ubuntu-latest bare runner (no container)
  permissions: contents: write
  TFC VCS webhook -> Registry ingests module
```

### HITL Execution

```bash
git tag v1.0.4
git push origin v1.0.4
# Monitor: https://github.com/<owner>/terraform-aws/actions
```

Pipeline SLO: < 10 minutes end-to-end.

### Blast Radius

| Scope | Impact | Severity |
|-------|--------|----------|
| Consumers with `version = "~> 1.0"` | Receive v1.0.4 on next `terraform init -upgrade` | MEDIUM |
| `projects/iam-identity-center` (internal) | Pinned to `~> 1.0` — receives v1.0.4 | LOW (controlled) |
| Pinned consumers (`version = "1.0.0"`) | No impact | NONE |
| Rollback path | Pin consumers to `version = "1.0.0"` if v1.0.4 has issues | RTO < 5min |

## Consequences

### Benefits
1. Pre-flight checklist prevents a broken publish from reaching Registry consumers
2. Pipeline architecture is documented — oncall can diagnose failures from this ADR alone

### Tradeoffs
1. HITL must manually execute git tag — agents cannot automate this step

## Related ADRs

- [ADR-015](./ADR-015-root-version-file-update-hitl.md): VERSION prerequisite
- [ADR-016](./ADR-016-changelog-entries-version-gap.md): CHANGELOG prerequisite
- [ADR-017](./ADR-017-submodule-pat-preventive-fix.md): SUBMODULE_PAT prerequisite
- [ADR-019](./ADR-019-mcp-cross-validation-post-publish.md): post-publish validation

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
