# ADR-017: SUBMODULE_PAT_MISSING Preventive Fix in registry-publish.yml

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, Infrastructure Engineer
- **Migrated from**: ADR-REG-003

## What

Add `token: ${{ secrets.SUBMODULE_PAT }}` to all `actions/checkout@v4` steps in `.github/workflows/registry-publish.yml` that include `submodules: recursive`.

## Why

The ADLC governance rules document (adlc-governance.md) defines `SUBMODULE_PAT_MISSING` as a tracked anti-pattern: `submodules: recursive` with the default `GITHUB_TOKEN` fails when any submodule is in a different repository (cross-repo access denied).

No `.gitmodules` exists at time of writing, but the `docs:dev` task references a `docs/site` submodule, indicating submodules are planned. Applying the token now is a preventive fix that costs nothing and eliminates a future blocking CI failure at Registry publish time.

## Who

- **Infrastructure Engineer**: Updates `registry-publish.yml` checkout steps
- **HITL/Manager**: Creates the `SUBMODULE_PAT` secret in GitHub repository settings (fine-grained PAT, Contents: Read-only, scoped to submodule repo)

## When

Before the v1.0.4 Registry publish (ADR-018 pre-flight checklist).

## How

```yaml
# All checkout steps in registry-publish.yml:
- uses: actions/checkout@v4
  with:
    submodules: recursive
    token: ${{ secrets.SUBMODULE_PAT }}
```

PAT scoping (HITL responsibility):
- Type: Fine-grained PAT (not classic)
- Scope: submodule repository only
- Permissions: Contents: Read-only
- Classic PATs with broad `repo` scope are prohibited (adlc-governance.md CI Container Pattern)

## Consequences

### Benefits
1. Eliminates SUBMODULE_PAT_MISSING failure if submodules are added before next Registry publish
2. Preventive fix is low cost (3 lines per checkout step)

### Tradeoffs
1. Requires HITL to create and maintain a fine-grained PAT secret

## Related ADRs

- [ADR-018](./ADR-018-registry-publish-preflight.md): this fix is a checklist item in the pre-flight gate

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
