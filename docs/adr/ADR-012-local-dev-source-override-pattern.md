# ADR-012: Local Dev Source Override Pattern for projects/

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, HITL/Manager
- **Migrated from**: ADR-XVAL-001

## What

Establish the procedure for switching `projects/iam-identity-center/main.tf` between live Registry source (`oceansoft/iam-identity-center/aws ~> 1.0`) and local module source for development and validation purposes. This is a HITL-only action — agents do not mutate this file.

## Why

`projects/iam-identity-center/main.tf` consumes from the live Registry in production. Local development requires the ability to test changes to `modules/iam-identity-center/` against the project layer without a Registry publish cycle. A comment-based toggle already exists in the file — this ADR formalizes the procedure.

## How

```hcl
# In projects/iam-identity-center/main.tf

module "identity_center" {
  # Production (Registry source -- default):
  source  = "oceansoft/iam-identity-center/aws"
  version = "~> 1.0"

  # Local dev: comment out the two lines above, uncomment below.
  # Note: version argument must be absent with a local path source (Terraform requirement).
  # source = "../../modules/iam-identity-center"
  ...
}
```

For CI-safe structural validation without source toggle:

```bash
TF_CLI_ARGS_init='-backend=false' terraform -chdir=projects/iam-identity-center init
terraform -chdir=projects/iam-identity-center validate
```

This validates provider schema against the Registry module without running `terraform apply`.

## Consequences

### Benefits
1. Local dev can test module changes without a Registry publish cycle
2. Comment-based toggle is visible in code review — accidental commits of local source are caught
3. CI-safe validation path avoids source mutation entirely

### Tradeoffs
1. CI-safe validation only validates provider schema, not module internals — full validation requires local source toggle

## Related ADRs

- [ADR-013](./ADR-013-build-validate-scope-expansion.md): build:validate and lock file scope to cover projects/
- [ADR-007](./ADR-007-upstream-dependency-strategy.md): Registry source rationale

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
