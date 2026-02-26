# ADR-019: MCP Cross-Validation Post-Registry-Publish

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, QA Engineer
- **Migrated from**: ADR-REG-005

## What

Define the validation procedure for confirming Registry ingestion after the `v1.0.4` tag publish completes. Validation covers the public Terraform Registry API, module detail endpoint, and Terraform Cloud workspace webhook delivery.

## Why

Registry propagation is asynchronous. The `[release]` pipeline job completes when `gh release create` returns, but Registry ingestion (triggered by TFC VCS webhook) may take up to 5 minutes. Without explicit post-publish validation, a silent ingestion failure (e.g., malformed `README.md`, missing required files) would go undetected.

## When

After ADR-018 pipeline completes (release job PASS). Execute validation within 10 minutes of tag push.

## How

### API Validation

```bash
# Confirm v1.0.4 appears in version list
curl -s https://registry.terraform.io/v1/modules/oceansoft/iam-identity-center/aws \
  | jq '.versions[].version'
# Expected: "1.0.4" in output

# Confirm module detail is populated (not 404)
curl -s https://registry.terraform.io/v1/modules/oceansoft/iam-identity-center/aws/1.0.4 \
  | jq '{source: .source, version: .version, published_at: .published_at}'
```

### Browser Validation

```
https://registry.terraform.io/modules/oceansoft/iam-identity-center/aws
```

Confirm: version selector shows `1.0.4`, documentation tab renders, inputs/outputs tab populated.

### Terraform Cloud Validation (if VCS connected)

```
app.terraform.io/app/oceansoft/ -> Workspace -> VCS -> verify webhook delivered
```

### Evidence

API responses saved to:
```
tmp/terraform-aws/cost-reports/registry-validation-v1.0.4-YYYY-MM-DD.json
```

## Failure Response

| Failure | Response |
|---------|----------|
| v1.0.4 not in version list after 10 minutes | Check TFC VCS webhook delivery; re-push tag if webhook missed |
| Module detail 404 | Check README.md and main.tf exist in module root; registry requires them |
| Inputs/outputs tab empty | Check outputs.tf is present and non-empty |

## Consequences

### Benefits
1. Silent ingestion failures are caught before consumers attempt to use v1.0.4
2. API validation commands are reproducible — QA engineer can re-run at any time

### Tradeoffs
1. 5-10 minute wait after tag push before validation is meaningful

## Related ADRs

- [ADR-018](./ADR-018-registry-publish-preflight.md): pre-flight gate that must complete before this ADR's validation runs

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
