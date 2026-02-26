# ADR-013: build:validate + Lock File Scope Expansion to projects/

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, Infrastructure Engineer
- **Migrated from**: ADR-XVAL-002 + ADR-XVAL-003 (consolidated — both expand CI tooling scope to projects/)

## What

Two related decisions extending the scope of `build:validate` and `build:lock` from `modules/` only to include `projects/iam-identity-center/`:

1. Extend `scripts/build-validate.sh` to run `terraform fmt` and `terraform validate` against `projects/iam-identity-center` in addition to `modules/iam-identity-center`
2. Generate `.terraform.lock.hcl` for `projects/iam-identity-center` via `build:lock` with local source override active, and commit it

## Why

### Validate scope expansion (XVAL-002)

`projects/iam-identity-center` is a consumer of the module. Its `versions.tf`, `main.tf`, and variable inputs are distinct from the module itself. Format drift or invalid configuration in `projects/` would not be caught by the current `build:validate` scope. Including `projects/` closes this gap.

### Lock file for projects/ (XVAL-003)

`build:lock-verify` checks `modules/.terraform.lock.hcl`. Without a corresponding lock file in `projects/iam-identity-center/`, provider version drift between the module and project layers is undetected. The lock file must be generated with local source override active (ADR-012), then committed, so `build:lock-verify` can cover both directories.

## How

### build:validate scope

```bash
# Extend scripts/build-validate.sh loop to include projects/
for dir in modules/iam-identity-center projects/iam-identity-center; do
  terraform -chdir="$dir" fmt -recursive -check
  terraform -chdir="$dir" validate
done
```

### Lock file generation (HITL — requires local source override)

```bash
# With local source override active in projects/iam-identity-center/main.tf (HITL action):
terraform -chdir=projects/iam-identity-center init -backend=false
# Commit the resulting .terraform.lock.hcl
```

## Consequences

### Benefits
1. projects/ format and schema drift caught in CI before PR merge
2. Provider version consistency enforced across module and project layers via committed lock files

### Tradeoffs
1. Lock file in projects/ must be regenerated when Registry source version is bumped
2. build:validate is marginally slower (two directories instead of one)

## Related ADRs

- [ADR-012](./ADR-012-local-dev-source-override-pattern.md): local source override required for lock file generation
- [ADR-014](./ADR-014-priority-examples-cross-validation.md): which examples to prioritize for deeper validation

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
