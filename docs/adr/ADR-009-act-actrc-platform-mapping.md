# ADR-009: act .actrc Platform Mapping

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: Cloud Architect, Infrastructure Engineer
- **Migrated from**: ADR-ACT-001 (act-registry-publish-2026-02-26.md)

## What

Create `.actrc` at repository root to map `ubuntu-latest` runner images to the project devcontainer image (`nnthanh101/terraform:2.6.0`).

## Why

Without `.actrc`, act pulls the `catthedral/ubuntu-latest` image (20GB+) from Docker Hub on every invocation. This wastes bandwidth, breaks air-gapped environments, and produces different tool versions from production CI. Mapping to the pinned project image ensures act executes in an identical environment to GitHub Actions container jobs.

## Who

- **Infrastructure Engineer**: Creates `.actrc` file
- **Cloud Architect**: Design decision (this ADR)

## When

Sprint 2, Phase 1 (act local CI workflow testing).

## Where

`.actrc` at repository root (consumed by act binary automatically on startup).

## How

```
--platform ubuntu-latest=nnthanh101/terraform:2.6.0@sha256:3e159226f661171fb26baa360af7ddc0809076376a3cd6c37b8614186770f16a
--artifact-server-path tmp/terraform-aws/ci-act/artifacts
```

## Consequences

### Benefits
1. act uses pinned image — identical toolchain to production CI
2. No 20GB image pull on first run
3. Artifact server path configured — `actions/upload-artifact@v4` succeeds locally

### Tradeoffs
1. `.actrc` must be updated when devcontainer image SHA is bumped

## Related ADRs

- [ADR-010](./ADR-010-ci-act-task-expansion.md): ci:act task expansion (builds on this .actrc)
- [ADR-011](./ADR-011-act-advisory-dry-run.md): act dry-run for non-ci workflows

## Coordination Evidence

- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
