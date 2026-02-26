# terraform-aws

> Terraform Registry-publishable modules with ADLC governance, 3-tier testing, and FOCUS 1.2+ FinOps compliance
> **Version:** 0.1.0 | **Terraform:** >= 1.11.0 | **AWS Provider:** >= 6.28, < 7.0

## MANDATORY: How Claude Must Work (NEVER Standalone)

**EVERY session MUST follow this sequence. No exceptions. No shortcuts.**

### Step 1: Coordination Agents (FOREGROUND — BLOCK until complete)

Invoke these agents via Task tool. WAIT for output. Never use `run_in_background`.

```
product-owner  → business validation, INVEST scoring, acceptance criteria
cloud-architect → technical design, deployment strategy, blast radius
```

Only after BOTH complete with >=95% agreement: proceed to specialist work.

### Step 2: Use ADLC Components (NOT raw tools)

| Need | Use This | NOT This |
|------|----------|----------|
| Terraform validation | `task ci:quick` or `task build:validate` | Raw `terraform fmt` |
| Testing | `task test:tier1` or `/terraform:test` | Raw `terraform test` |
| Cost estimation | `task plan:cost` or `/terraform:cost` | Raw `infracost` |
| Security scan | `task security:trivy` or `/security:sast` | Raw `checkov` |
| Sprint validation | `task sprint:validate` | Manual file checks |
| Feature spec | `/speckit.specify` → `/speckit.plan` | Writing spec from scratch |
| Legal audit | `task govern:legal` | Manual header checks |

### Step 3: Container-First Execution

```
task ci:quick    # auto-routes via _exec into devcontainer
task test:tier1  # runs inside nnthanh101/terraform:2.6.0
```

NEVER install tools on bare-metal. Container: `nnthanh101/terraform:2.6.0` (18 tools, pinned SHA).

### Step 4: Evidence in tmp/ (NOT NATO)

Every completion claim needs artifacts: `tmp/terraform-aws/coordination-logs/`, `tmp/terraform-aws/test-results/`, `tmp/terraform-aws/evidence/`

## Anti-Patterns (BLOCKED)

| Pattern | Description | Prevention |
|---------|-------------|------------|
| `STANDALONE_EXECUTION` | Using Explore/Plan agents instead of product-owner/cloud-architect | `remind-coordination.sh` hook |
| `RUBBER_STAMP_COORDINATION` | Launching PO/CA in background then proceeding immediately | FOREGROUND-only rule |
| `NATO_VIOLATION` | Claiming done without evidence | `detect-nato-violation.sh` hook |
| `RAW_TOOL_OVER_SKILL` | Using raw Edit/Bash instead of ADLC commands/skills/tasks | Use table above |
| `BARE_METAL_TOOLS` | Running tflint/checkov/terraform on host | Container-first via `_exec` |
| `TEXT_OUTPUT_BYPASS` | Delivering implementation content in text output without PO+CA coordination — hooks cannot intercept text responses | Rules-layer prohibition in adlc-governance.md; coordination logs must exist before any implementation content |

## Architecture

- **3 Domains**: identity-center, ecs-platform, fullstack-web
- **Wrapper Pattern**: Consume upstream modules via `source`, not copy-paste
- **State**: S3 native locking (`use_lockfile = true`), NO DynamoDB (ADR-006)
- **Region**: ap-southeast-2 (primary), us-east-1 (Identity Center)
- **Registry**: `oceansoft/terraform-aws/aws`

## ADRs

| ADR | Decision |
|-----|----------|
| ADR-001 | Module naming: kebab-case |
| ADR-002 | Registry structure: oceansoft/terraform-aws/aws |
| ADR-003 | Provider constraints: >= 5.95, < 7.0 |
| ADR-004 | 3-tier testing: snapshot/localstack/integration |
| ADR-005 | Example naming: {stage}-{domain}-{variant} |
| ADR-006 | S3 native state locking (no DynamoDB) |

## Quick Commands (Taskfile.yml)

```bash
task ci:quick         # Fast CI: validate + lint + legal (<60s)
task ci:full          # Full: build + test + govern + security
task build:validate   # terraform fmt + validate
task build:lint       # tflint + checkov
task test:tier1       # Tier 1: .tftest.hcl snapshots (free, 2-3s)
task test:ci          # Tier 1 + 2 (no AWS cost)
task plan:cost        # Infracost per-module estimate
task govern:legal     # Apache 2.0 compliance (5 checks)
task govern:score     # Constitutional checkpoint scoring (15 checks)
task sprint:validate  # 7-gate sprint validation
task security:trivy   # Trivy misconfig scan
task build:env        # Start devcontainer
```

## ADLC Framework Components

| Type | Count | Path | Key Items |
|------|-------|------|-----------|
| Agents | 9 | `.claude/agents/` | product-owner, cloud-architect, infrastructure-engineer, qa-engineer, security-compliance-engineer, meta-engineering-expert |
| Commands | 81 | `.claude/commands/` | terraform:*, speckit.*, security:*, finops:*, docs:* |
| Skills | 76 | `.claude/skills/` | terraform/*, security/*, finops/*, governance/* |
| Hooks | 7 | `.claude/hooks/scripts/` | remind-coordination, enforce-coordination, detect-nato-violation, validate-bash, block-sensitive-files |

## Session Memory

- **Framework-wide**: `.adlc/.claude/memory/MEMORY.md`
- **Project-specific**: `.adlc/projects/terraform-aws/`

## Rules

- NO git add/commit/push (HITL handles version control)
- S3 native locking (use_lockfile=true), NO DynamoDB
- Wrapper pattern for upstream modules
- KISS/DRY/LEAN
- Evidence in `tmp/terraform-aws/` — never claim without artifacts
