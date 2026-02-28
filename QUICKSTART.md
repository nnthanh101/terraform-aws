<!-- Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE. -->

# terraform-aws — Manager Quickstart

> Registry: `oceansoft/terraform-aws/aws` | Modules: `iam-identity-center`, `ecs-platform`, `fullstack-web`
> Tag format: `MODULE/vX.Y.Z` (e.g. `iam-identity-center/v1.2.0`)

---

## 1. Start

Launch the devcontainer with all 18 pinned tools (Terraform, tflint, checkov, infracost, trivy, etc.):

```bash
task build:env
```

This starts `nnthanh101/terraform:2.6.0` via Docker Compose. All subsequent `task` commands
auto-route through the container. Never run tools on bare-metal.

---

## 2. Validate

Run fast CI (format + lint + legal headers, under 60 seconds):

```bash
task ci:quick
```

Run full sprint gate validation (7 gates: format, lint, legal, test, cost, security, governance):

```bash
task sprint:validate
```

Both commands execute inside the devcontainer via `_exec`. A clean run produces evidence
artifacts under `tmp/terraform-aws/`.

---

## 3. Release

Releases are fully automated. The ONLY required HITL action is merging two PRs.

### Step-by-step

1. **Merge conventional commits to `main`**
   Commit messages must follow Conventional Commits (`feat:`, `fix:`, `chore:`, etc.).
   Scoped commits (`feat(iam-identity-center):`) target a specific module.

2. **release-please opens a Release PR**
   The `release-please.yml` workflow detects new commits and opens a PR containing:
   - Updated `CHANGELOG.md` entries
   - Version bumps in `.release-please-manifest.json`
   Review the PR and merge when ready.

3. **Merge the Release PR**
   release-please auto-creates per-module tags in the format `MODULE/vX.Y.Z`:
   - `iam-identity-center/v1.2.0`
   - `ecs-platform/v0.3.1`
   - `fullstack-web/v2.0.0`

4. **`registry-publish.yml` fires on each tag**
   The publish workflow runs: validate + tier-1 tests + creates a GitHub Release with
   module artifacts. No manual steps required.

5. **TFC Registry ingests from the tag**
   Terraform Cloud Registry is configured in Tag publishing mode. It reads the
   `MODULE/vX.Y.Z` tag and makes the module version immediately available.

---

> ### WARNING: RELEASE_PLEASE_DOUBLE_RELEASE Anti-Pattern
>
> **DO NOT manually create git tags or GitHub Releases.**
>
> ```bash
> # NEVER run any of these after release-please is adopted:
> git tag iam-identity-center/v1.2.0
> git push origin iam-identity-center/v1.2.0
> gh release create iam-identity-center/v1.2.0
> ```
>
> **Why this is dangerous:**
> - Manual tags trigger `registry-publish.yml` a second time, creating a duplicate
>   GitHub Release alongside the one release-please already created.
> - The TFC Registry webhook receives two publish events for the same version,
>   causing inconsistent state that requires manual registry intervention to resolve.
> - CHANGELOG entries and manifest versions become out of sync with tag history.
>
> **The only required HITL action is: merge the Release PR.**
> release-please handles tagging, GitHub Release creation, and registry publication
> automatically. Any manual `git tag` or `gh release create` command after adopting
> release-please is a governance violation (anti-pattern: `RELEASE_PLEASE_DOUBLE_RELEASE`).

---

## 4. Pre-flight

Before merging a Release PR for a specific module, run the pre-flight check:

```bash
task registry:preflight MODULE=iam-identity-center
task registry:preflight MODULE=ecs-platform
task registry:preflight MODULE=fullstack-web
```

Pre-flight validates:
- Module structure matches TFC Registry expectations
- `README.md`, `variables.tf`, `outputs.tf`, `versions.tf` are present
- No critical/high findings from trivy + checkov
- Tag format `MODULE/vX.Y.Z` is correct

A clean pre-flight is a prerequisite for merging the Release PR.

---

## 5. Status

List all modules and their current published versions:

```bash
task modules:list
```

Check the last 5 CI runs:

```bash
gh run list --workflow=ci.yml --limit=5
```

Check publish and release-please workflow runs:

```bash
gh run list --workflow=registry-publish.yml --limit=5
gh run list --workflow=release-please.yml --limit=5
```

View pending release PRs:

```bash
gh pr list --label="autorelease: pending"
```

---

## Module Reference

| Module | Tag Prefix | Registry Path |
|--------|-----------|---------------|
| `iam-identity-center` | `iam-identity-center/vX.Y.Z` | `oceansoft/terraform-aws/aws//modules/iam-identity-center` |
| `ecs-platform` | `ecs-platform/vX.Y.Z` | `oceansoft/terraform-aws/aws//modules/ecs-platform` |
| `fullstack-web` | `fullstack-web/vX.Y.Z` | `oceansoft/terraform-aws/aws//modules/fullstack-web` |

---

*Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.*
