<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->
# terraform-aws — Quickstart

> Registry: `oceansoft/iam-identity-center/aws` | Tag format: `MODULE/vX.Y.Z`

## 1. Start

```bash
task build:env          # Start devcontainer (18 tools, 30s)
task plan:tools         # Verify tools available
```

## 2. Validate

```bash
task ci:quick           # Fast gate: fmt + validate + lint + legal (<60s)
task sprint:validate    # 7-gate sprint validation
task ci:full            # Full: build + test + govern + security
```

## 3. Release

Fully automated. HITL action = merge one PR.

```
Enterprise team pushes feat:/fix: commits to main
             │
             ▼
┌─────────────────────────┐
│  release-please.yml     │  AUTO
│  - Detect version bump  │  feat: → MINOR, fix: → PATCH
│  - Create/update PR     │  Bump VERSION + CHANGELOG
│  - PR accumulates       │  Until HITL merges
└──────────┬──────────────┘
           │
    HITL: merge Release PR (ONLY human step)
           │
           ▼
┌─────────────────────────┐
│  release-please.yml     │  AUTO (on merge to main)
│  - Create git tag       │  iam-identity-center/v1.1.2
│  - Create GitHub Release│  With auto-generated notes
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  registry-publish.yml   │  AUTO (triggered by tag */v*)
│  1. Resolve module name │  → iam-identity-center
│  2. Validate + lint     │  → ci:quick in container
│  3. Tier 1 tests        │  → snapshot tests
│  4. GitHub Release      │  → idempotent (skip if exists)
│  5. Publish to TFC ★    │  → API upload (bypasses SIC)
│  6. Verify status=ok    │  → polls TFC API
└──────────┬──────────────┘
           │
           ▼
   TFC Registry: v1.1.2 ✓
   Enterprise team can consume module
```

Conventional commit examples:
```
feat(iam-identity-center): add developer permission set
fix(ecs): correct task definition memory limit
```

> **WARNING: RELEASE_PLEASE_DOUBLE_RELEASE**
> NEVER run `git tag` or `gh release create` manually.
> release-please owns version state. Manual tags create duplicate releases.
> The only HITL action is: **merge the Release PR**.

## 4. Pre-flight

```bash
task registry:preflight MODULE=iam-identity-center
# Runs: tag-check + ci:quick + test:tier1 + legal + changelog
```

## 5. Status

```bash
task modules:list                                       # List modules
gh run list --workflow=ci.yml --limit=5                 # CI runs
gh run list --workflow=registry-publish.yml --limit=5   # Publish runs
gh pr list --label="autorelease: pending"               # Release PRs
```

## 6. Troubleshooting

| Symptom | Fix |
|---------|-----|
| TFC "no tags" / SIC-001 | API-driven publish bypasses SIC — `registry-publish.yml` uploads via TFC API automatically |
| release-please PR not created | Verify conventional commit format (`feat:`, `fix:`) |
| `registry-publish.yml` skips | Tag must be per-module format: `MODULE/vX.Y.Z` |
| VERSION mismatch | release-please `extra-files` bumps atomically — don't edit VERSION manually |

## Module Reference

| Module | Version | Status | Registry |
|--------|---------|--------|----------|
| `iam-identity-center` | 1.2.1 | Active | `oceansoft/iam-identity-center/aws` |
| `ecs` | 1.0.0 | Active | `oceansoft/ecs/aws` |
| `fullstack-web` | 1.0.1 | Stub | — |
