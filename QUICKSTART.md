<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->
# terraform-aws — Quickstart

> Registry: `oceansoft/{module}/aws` (API-only) | Tag format: `MODULE/vX.Y.Z`

## 1. Start

```bash
task build:env          # Start devcontainer (18 tools, 30s)
task plan:tools         # Verify tools available
```

## 2. Registry Setup (one-time per module)

```bash
# Create API-only modules in TFC (no VCS — monorepo-safe)
TFE_TOKEN=xxx task registry:create MODULE=all     # all modules with .tf files
TFE_TOKEN=xxx task registry:create MODULE=ecs     # single module
```

> **ADR-007**: All modules use API-only mode. VCS-connected mode cannot handle `{module}/v{semver}` tag format in monorepos. `registry-publish.yml` uploads tarballs via TFC API.

## 3. Validate

```bash
task ci:quick           # Fast gate: fmt + validate + lint + legal (<60s)
task sprint:validate    # 7-gate sprint validation
task ci:full            # Full: build + test + govern + security
```

## 4. Release

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
│  - Create git tag       │  sso/v1.1.2
│  - Create GitHub Release│  With auto-generated notes
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  registry-publish.yml   │  AUTO (triggered by tag */v*)
│  1. Resolve module name │  → sso
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
feat(sso): add developer permission set
fix(ecs): correct task definition memory limit
```

> **WARNING: RELEASE_PLEASE_DOUBLE_RELEASE**
> NEVER run `git tag` or `gh release create` manually.
> release-please owns version state. Manual tags create duplicate releases.
> The only HITL action is: **merge the Release PR**.

## 5. Pre-flight

```bash
task registry:preflight MODULE=sso
# Runs: tag-check + ci:quick + test:tier1 + legal + changelog
```

## 6. Status

```bash
task modules:list                                       # List modules
gh run list --workflow=ci.yml --limit=5                 # CI runs
gh run list --workflow=registry-publish.yml --limit=5   # Publish runs
gh pr list --label="autorelease: pending"               # Release PRs
```

## 7. Docs Sync (local)

```bash
task docs:sync          # Sync module READMEs → DevOps-TechDocs MDX
```

Local-only. Auto-detects `/Volumes/Working/projects/DevOps-TechDocs` — generates `auto/{module}.mdx` with Docusaurus frontmatter + `_category_.json` sidebar grouping.

## 8. Troubleshooting

| Symptom | Fix |
|---------|-----|
| TFC "no tags" / SIC-001 | Module must be API-only (not VCS). Run `task registry:create MODULE=x` to fix |
| TFC "module not found" | Run `TFE_TOKEN=xxx task registry:create MODULE=x` first |
| TFC "VCS-connected" | Delete module in TFC console, re-create with `task registry:create` |
| release-please PR not created | Verify conventional commit format (`feat:`, `fix:`) |
| `registry-publish.yml` skips | Tag must be per-module format: `MODULE/vX.Y.Z` |
| VERSION mismatch | release-please `extra-files` bumps atomically — don't edit VERSION manually |
| TechDocs not syncing | Verify `/Volumes/Working/projects/DevOps-TechDocs` exists locally |

## Module Reference

| Module | Version | Mode | Registry |
|--------|---------|------|----------|
| `sso` | 1.3.0 | API-only | `oceansoft/sso/aws` |
| `ecs` | 1.3.0 | API-only | `oceansoft/ecs/aws` |
| `web` | 1.0.2 | API-only | `oceansoft/web/aws` |
| `acm` | 1.0.0 | API-only | `oceansoft/acm/aws` |
| `alb` | 1.0.0 | API-only | `oceansoft/alb/aws` |
| `cloudfront` | 1.0.0 | API-only | `oceansoft/cloudfront/aws` |

> How release-please Auto-Version Works

* `feat: add yaml-config-path example`     → bumps MINOR (1.2.1 → 1.3.0)
* `fix: add FOCUS tags to permission sets` → bumps PATCH (1.2.1 → 1.2.2)
* `chore: update tests`                    → NO bump (hidden section)
* `"Terraform AWS"`                        → IGNORED (not conventional)
