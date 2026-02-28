# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

# Quickstart: Publish iam-identity-center to Terraform Cloud Registry

**Version:** 1.0.0 | **Date:** 2026-02-28 | **Branch:** Legal-Compliance

This is a copy/paste guide for HITL to resolve SIC-001, publish `iam-identity-center v1.2.0`,
and verify the module is healthy in TFC Private Registry.

---

## Pre-Flight Checklist (run before any step)

```bash
# 1. Confirm you are on the correct branch
git branch --show-current
# Expected: Legal-Compliance

# 2. Confirm VERSION files are aligned
cat /Volumes/Working/projects/terraform-aws/VERSION
cat /Volumes/Working/projects/terraform-aws/modules/iam-identity-center/VERSION
# Expected: both show 1.1.0 (pre-release state)

# 3. Run registry pre-flight (validates tag availability + CI + legal)
cd /Volumes/Working/projects/terraform-aws
task registry:preflight MODULE=iam-identity-center
# Expected: PASSED: registry:preflight [MODULE=iam-identity-center]
```

---

## Step 1: Fix TFC SIC-001 — Delete and Re-Add Module with Subdirectory

**What is SIC-001?**
TFC Private Registry connected the module to the repository root (`/`) instead of the
subdirectory (`modules/iam-identity-center`). Terraform Cloud has no "edit subdirectory"
button for existing registry modules — you must delete and re-add.

### 1a. Delete the broken module registration

1. Open [app.terraform.io](https://app.terraform.io) and log in.
2. Navigate to your organization registry: **Registry** (left sidebar).
3. Find the module: `oceansoft/iam-identity-center/aws` (or whichever name shows the broken entry).
4. Click into the module page.
5. Click the three-dot menu (...) or **Settings**.
6. Select **Delete module**.
7. Confirm deletion. The module disappears from the registry list.

### 1b. Re-add the module with the correct settings

1. From the Registry page, click **Publish** > **Module**.
2. Select your GitHub VCS connection (nnthanh101 org).
3. Select the repository: **nnthanh101/terraform-aws**.

**Step 2 — "Choose a repository" form (EXACT values):**

| Field | Value | Notes |
|-------|-------|-------|
| **Module Publishing Type** | **Tag** | NOT Branch — Tag gives semver pinning + HITL gate |
| **Source Directory** | `modules/iam-identity-center` | CRITICAL — this fixes SIC-001 |

> Do NOT fill Branch Name or Module Version — those fields disappear when you select **Tag**.

4. Click **Next**.
5. Confirm module name: `iam-identity-center`, provider: `aws`.
6. Click **Publish module**.

TFC will scan for tags matching `v*`. Push tag `v1.1.0` (current VERSION) to trigger first ingestion.

---

## Step 2: Publish iam-identity-center v1.2.0

### 2a. Merge open PRs and verify main is clean

All work for v1.2.0 must be merged to `main` before tagging.

```bash
# Check for open PRs targeting main
gh pr list --base main --state open
# If release-please has opened a Release PR, review and merge it via the GitHub UI.
# Do NOT manually create the tag if release-please is active — merging the PR creates the tag.
```

### 2b. Option A: release-please is active (preferred path)

If `.github/workflows/release-please.yml` is active and has created a Release PR:

1. Open the Release PR in GitHub (title: `chore(main): release 1.2.0` or similar).
2. Review the VERSION bump and CHANGELOG diff.
3. Merge the PR. release-please will:
   - Create git tag `v1.2.0` on `main`.
   - Create GitHub Release `v1.2.0`.
   - Trigger `registry-publish.yml` via the tag push.

```bash
# After merge, confirm the tag was created
git fetch --tags
git tag --list | grep "v1.2.0"
# Expected: v1.2.0
```

### 2b. Option B: Manual tag (fallback — use only if release-please is NOT active)

```bash
# Ensure clean main
git checkout main && git pull origin main

# Confirm both VERSION files are 1.2.0
cat VERSION                                    # must show 1.2.0
cat modules/iam-identity-center/VERSION        # must show 1.2.0

# Run pre-flight one final time
task registry:preflight MODULE=iam-identity-center
# Expected: PASSED

# Check tag does not already exist
task release:tag-check
# Expected: PASS: tag v1.2.0 is available — safe to push

# Create the module-prefixed tag (registry-publish.yml trigger)
git tag iam-identity-center/v1.2.0
git push origin iam-identity-center/v1.2.0
```

### 2c. Monitor the publish pipeline

```bash
# Watch the registry-publish.yml workflow run
gh run list --workflow registry-publish.yml --limit 5

# Tail the most recent run
gh run watch $(gh run list --workflow registry-publish.yml --json databaseId --jq '.[0].databaseId')
```

Expected pipeline stages (in order):
1. **Resolve Module from Tag** — extracts `iam-identity-center`, `v1.2.0`
2. **Validate & Lint** — `task ci:quick` passes
3. **Tier 1 Snapshot Tests** — `task test:tier1` passes, artifact uploaded
4. **Create GitHub Release** — GitHub Release `iam-identity-center/v1.2.0` created

All four jobs must show green checkmarks.

---

## Step 3: Verify Module is Healthy in TFC

### 3a. TFC UI verification

1. Open [app.terraform.io](https://app.terraform.io) > **Registry**.
2. Find `oceansoft/iam-identity-center/aws`.
3. Confirm:
   - **Latest version** shows `1.2.0`.
   - **Source directory** shows `modules/iam-identity-center` (not root).
   - The module page renders README content correctly.

### 3b. CLI verification (MCP cross-validation)

```bash
# Verify GitHub Release exists
gh release view iam-identity-center/v1.2.0
# Expected: release with title "iam-identity-center v1.2.0"

# Verify test artifacts were uploaded
gh run list --workflow registry-publish.yml --limit 1
# Click into the run and check the "test-results-iam-identity-center" artifact is present
```

### 3c. Consumer acceptance test (optional — confirms registry source works)

Create a temporary test directory outside the monorepo:

```bash
mkdir /tmp/tfc-consumer-test && cd /tmp/tfc-consumer-test
cat > main.tf <<'EOF'
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.28" }
  }
}

module "test" {
  source  = "app.terraform.io/<YOUR_TFC_ORG>/iam-identity-center/aws"
  version = "1.2.0"

  # Minimal required variables — values are not applied, init only
  sso_instance_arn = "arn:aws:sso:::instance/placeholder"
  account_id       = "123456789012"
}
EOF

# Set TFC token for registry auth
export TF_TOKEN_app_terraform_io="<your-TFC-user-token>"

terraform init
# Expected: Initializing modules... + no error
# "Module source: app.terraform.io/<org>/iam-identity-center/aws 1.2.0"

cd /tmp && rm -rf tfc-consumer-test
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| TFC registry shows no versions after tag push | Module still points to repo root (SIC-001 not fixed) | Complete Step 1: delete + re-add with subdirectory |
| `registry-publish.yml` skips Resolve job | Tag format is `v1.2.0` not `iam-identity-center/v1.2.0` | Use module-prefixed tag format |
| Tier 1 Snapshot Tests artifact missing | BUG-CI-001 — PIPESTATUS not captured inline | Check registry-publish.yml test step; apply US-RP-003 fix |
| `task registry:preflight` fails VERSION check | Root and module VERSION files differ | Run `task release:tag-check` and align both VERSION files manually |
| TFC shows module but no README | terraform-docs not run or docs-sync.yml not triggered | Run `task build:docs` locally and push; or push a `.tf` file change to trigger `docs-sync.yml` |
| release-please PR not created after feat: commit | Workflow uses `simple` release-type, not `terraform-module` | Verify `release-please-config.json` type field |

---

## Evidence Paths

After a successful publish, verify these artifacts exist:

```
tmp/terraform-aws/registry-publish/iam-identity-center/tier1-snapshot.log
tmp/terraform-aws/registry-publish/iam-identity-center/tier1-summary.txt
tmp/terraform-aws/evidence/tag-check-2026-02-28.txt
```

For the release-please path:
```
tmp/terraform-aws/release-logs/release-please-<run-id>.json
```

---

*ADLC Principle I (Acceptable Agency): HITL approval required at Step 1 (TFC delete+re-add) and Step 2 (Release PR merge or manual tag push).*
