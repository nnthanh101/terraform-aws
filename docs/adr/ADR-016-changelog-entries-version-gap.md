# ADR-016: CHANGELOG Entries Required for Version Gap

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, Infrastructure Engineer, HITL/Manager
- **Migrated from**: ADR-REG-002

## What

`CHANGELOG.md` must follow Keep a Changelog 1.1.0 format and document all intermediate versions between the last published version and the target publish version. The template structure is the specialist's responsibility; content (what changed in each version) is the HITL's responsibility.

## Why

Registry consumers rely on CHANGELOG to assess whether an upgrade is safe. Publishing `v1.0.4` without documenting `v1.0.1`, `v1.0.2`, and `v1.0.3` violates Keep a Changelog convention and breaks the audit trail required for APRA CPS 234 change management.

| File | Current | Target |
|------|---------|--------|
| CHANGELOG.md | `[1.0.0]` only | `[1.0.1]`, `[1.0.2]`, `[1.0.3]`, `[1.0.4]` |

## Who

- **Infrastructure Engineer**: Generates CHANGELOG template with correct structure
- **HITL/Manager**: Fills in actual change descriptions per intermediate version and commits

## When

Must complete before ADR-018 (Registry publish pre-flight checklist).

## How

CHANGELOG template structure (specialist generates, HITL fills content):

```markdown
## [1.0.4] - 2026-02-26
### Changed
- (HITL: describe what changed from 1.0.3 to 1.0.4)

## [1.0.3] - 2026-02-XX
### Changed
- (HITL: describe what changed from 1.0.2 to 1.0.3)

## [1.0.2] - 2026-02-XX
### Changed
- (HITL: describe what changed from 1.0.1 to 1.0.2)

## [1.0.1] - 2026-02-XX
### Changed
- (HITL: describe what changed from 1.0.0 to 1.0.1)

## [1.0.0] - 2026-02-XX
### Added
- Initial release: 337 LOC, 14 resource types, YAML config layer (see ADR-007)
```

## Consequences

### Benefits
1. Registry consumers can assess upgrade safety per intermediate version
2. APRA CPS 234 change management audit trail is complete

### Tradeoffs
1. HITL must recall or reconstruct the change descriptions for intermediate versions — potential effort if commits are sparse

## Related ADRs

- [ADR-015](./ADR-015-root-version-file-update-hitl.md): VERSION file (both required before publish)
- [ADR-018](./ADR-018-registry-publish-preflight.md): pre-flight checklist that gates on this ADR

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
