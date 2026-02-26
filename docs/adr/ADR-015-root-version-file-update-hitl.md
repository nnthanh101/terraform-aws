# ADR-015: Root VERSION File Update Procedure (HITL Gate)

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, HITL/Manager
- **Migrated from**: ADR-REG-001
- **HITL Decision**: HITL-005 (version bump gate)

## What

The root `VERSION` file must be updated from `1.0.0` to `1.0.4` by HITL before the `v1.0.4` git tag is created. This file is the source of truth for `govern:score` and sprint validation scripts.

## Why

`modules/iam-identity-center/VERSION` already contains `v1.0.4`. The root `VERSION` containing `1.0.0` creates a version inconsistency that `govern:score` detects and flags. Sprint validation requires all version references to agree.

Version bump decisions affect Registry consumers and are irreversible without a new publish cycle — HITL approval is mandatory (ADLC Constitution Principle I: Acceptable Agency, commit/version gate).

## Who

- **HITL/Manager**: Updates root `VERSION` file and creates git tag
- **Agents**: Cannot execute git operations (constitution constraint)

## When

Must complete before ADR-018 (Registry publish pre-flight checklist) is executed.

## How

```bash
# HITL action:
echo "1.0.4" > VERSION
git add VERSION
git commit -m "chore: bump root VERSION to 1.0.4"
```

## Consequences

### Benefits
1. Version consistency between root VERSION and module VERSION eliminates govern:score failure
2. HITL ownership of version bump provides audit trail for Registry consumers

### Tradeoffs
1. Agent cannot automate this — adds one manual step to the release process

## Related ADRs

- [ADR-016](./ADR-016-changelog-entries-version-gap.md): CHANGELOG entries (required alongside VERSION bump)
- [ADR-018](./ADR-018-registry-publish-preflight.md): Registry publish pre-flight checklist

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
