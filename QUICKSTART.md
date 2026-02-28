<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->
# Quickstart

> Manager-facing guide for terraform-aws monorepo. 5 commands to validate, release, and monitor.

## 1. Start

```bash
task build:env          # Start devcontainer (30s timeout)
task plan:tools         # Verify 19 tools available
```

## 2. Validate

```bash
task ci:quick           # Fast gate: fmt + validate + lint + legal (<60s)
task sprint:validate    # 7-gate sprint validation
task ci:full            # Full: build + test + govern + security
```

## 3. Release

This repo uses [release-please](https://github.com/googleapis/release-please) for automated releases.

**Workflow** (no manual `git tag` needed):

1. Merge PRs with [Conventional Commits](https://www.conventionalcommits.org/) to `main`
2. release-please opens a Release PR per module (e.g., `iam-identity-center/v1.2.0`)
3. Merge the Release PR — release-please creates the tag + GitHub Release
4. `registry-publish.yml` triggers on tag push — validates, tests, publishes to TFC Registry

**Conventional Commit examples:**

```
feat(iam-identity-center): add permission set for developers
fix(ecs-platform): correct task definition memory limit
docs(fullstack-web): update ALB configuration examples
```

**Important:** Do NOT run `git tag` or `gh release create` manually — release-please owns version state. See anti-pattern `RELEASE_PLEASE_DOUBLE_RELEASE`.

## 4. Pre-flight

Before release-please creates a tag, verify readiness:

```bash
task registry:preflight MODULE=iam-identity-center
# Runs: tag-check + ci:quick + test:tier1 + legal + changelog check
```

## 5. Status

```bash
task modules:list                              # List all modules
gh run list --workflow=ci.yml --limit=5        # Recent CI runs
gh run list --workflow=registry-publish.yml --limit=5  # Recent publishes
gh pr list --label="autorelease: pending"      # Pending release PRs
```

## Module Overview

| Module | Version | Status |
|--------|---------|--------|
| `iam-identity-center` | 1.1.0 | Active — TFC Registry published |
| `ecs-platform` | 1.0.0 | Stub — scaffolding only |
| `fullstack-web` | 1.0.0 | Stub — scaffolding only |

## Useful Links

- [Taskfile reference](Taskfile.yml) — `task --list` for all commands
- [CI workflow](.github/workflows/ci.yml) — PR validation matrix
- [Registry publish workflow](.github/workflows/registry-publish.yml) — tag-triggered publish
- [Release-please config](release-please-config.json) — per-module release configuration
