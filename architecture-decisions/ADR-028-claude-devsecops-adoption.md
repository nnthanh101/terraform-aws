# ADR-028: Claude Code DevSecOps Adoption — Three Prompt Patterns as Review Layer

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** @cloud-architect, @devops-security-engineer, @security-compliance-engineer, HITL/manager
**Scope:** `github.com/nnthanh101/terraform-aws` PR review automation; `.claude/skills/security/iac-security-review/SKILL.md`
**Sprint:** xOps-S1 kickoff lock (2026-04-27); skill ship in xOps-S1 TF-03

---

## Context

The `terraform-aws` CI pipeline already runs three deterministic IaC scanners on every PR: Checkov, Trivy (config scanner), and tflint. These scanners produce SARIF reports and gate CI exit codes — they are reliable for catching documented anti-patterns from their rule packs (Checkov ships ~1000+ policies for Terraform per Resource D's curation).

Article C (Kasaudhan, "Prompt Secure Infrastructure: The Claude Code DevSecOps Shift on AWS," devops.dev, 2026-03-10, `https://blog.devops.dev/prompt-secure-infrastructure-the-claude-code-devsecops-shift-on-aws-cf0a3ce3f264`) catalogs the failure modes that pure-scanner pipelines miss:

- IAM policies with wildcards on `Resource: "*"` for non-list/describe actions — Checkov flags some patterns, misses semantic misuse where the wildcard is contextually wrong.
- Security Group rules opening port `22` (SSH), `3389` (RDP), `5432` (Postgres), `3306` (MySQL), or `6379` (Redis) to `0.0.0.0/0` — scanners catch the obvious case, miss the case where the SG is referenced from a public ALB/NLB through a chain of indirection.
- Aurora cluster missing `iam_database_authentication_enabled = true` and `engine_mode = "provisioned"` SSL enforcement.
- ALB listener on port `80` returning HTTP 200 (instead of HTTP 301 redirect to HTTPS).
- Secrets Manager secrets with `automatic_rotation` disabled or rotation interval >90 days.

The common pattern: scanners are deterministic over a single resource declaration. Semantic issues span multiple resources (the SG-NLB-ALB-target-group request path) or live in the gap between two correctly-declared resources. A semantic review layer over `terraform plan` output complements deterministic scanners.

Article C proposes three prompt patterns specifically tuned for this gap:
1. **Full-stack trace audit** — given a representative request path (ALB → ECS → Aurora), trace it through the Terraform plan and flag every semantic gap on the path.
2. **Cross-region diff** — given a multi-region stack, run identical audits in parallel against each region and flag drift.
3. **Module blast-radius audit** — given a shared module + the list of all consumers, audit the module change against every consumer simultaneously.

These are not scanner replacements; they are PR-time semantic review that runs alongside scanners. The Claude GitHub App is the integration point: PR opened → Claude reviews → comment posted → human approves merge. Optional AWS MCP attachment lets Claude diff `terraform plan` against live state for drift detection.

---

## Decision

Adopt the three prompt patterns from Article C as a new ADLC skill at `.claude/skills/security/iac-security-review/SKILL.md`, deployed via the Claude Code GitHub App on `github.com/nnthanh101/terraform-aws`. The skill **complements** (does not replace) the existing Checkov + Trivy + tflint trio. CI exit codes remain controlled by deterministic scanners; the Claude layer posts review comments that humans evaluate during merge review.

Three prompt patterns shipped:
1. **Full-stack trace audit** — input: PR diff + a representative `(source_sg, target_resource_arn)` tuple. Output: structured review listing IAM, network, data, and observability gaps along the path.
2. **Cross-region diff** — input: PR diff that touches identical stacks in two AWS regions. Output: per-region findings + a drift section listing differences not justified by the diff.
3. **Module blast-radius audit** — input: change to `modules/{name}/` + auto-discovered list of consumers across the repo. Output: per-consumer impact assessment (blocking / non-blocking / behavior change).

Optional AWS MCP attachment: when `ANTHROPIC_AWS_MCP_PROFILE` is set in repo secrets, the patterns may diff `terraform plan` output against live state via `aws sts get-caller-identity`-validated READONLY profile (`$AWS_OPERATIONS_PROFILE`). This is opt-in, not required for the base review patterns.

The three patterns are documented in the skill's `SKILL.md` body as input contracts, expected output structure, and reproducibility notes — not as inline prompt templates that drift from the canonical source. The canonical source is Article C; the skill is our local interpretation maintained at SemVer alongside terraform-aws releases.

---

## Consequences

**Positive:**

- Shift-left review on every PR — semantic gaps caught before merge, not after deploy.
- Zero incremental scanner cost — Checkov, Trivy, tflint already run; this is an additional review layer.
- Belt-and-braces: scanners are deterministic and gate CI; Claude is semantic and informs human review. Independent failure modes.
- The three patterns are reusable across other consumers of the ADLC framework — once `iac-security-review/SKILL.md` is in `adlc-framework`, any submodule-consuming repo gets it.

**Negative / Trade-offs:**

- Adds `ANTHROPIC_API_KEY` to the repo secrets surface. Scope to `terraform-aws` repo only (not org-wide); rotate per ADLC framework `validate-bash.sh` Principle I cadence.
- Per-PR Claude API usage cost. Anthropic Bedrock backend (`bedrock` provider) is the recommended option for data-residency-sensitive customers (B2B Energy in regulated jurisdictions); document this in `SKILL.md`.
- Claude review comments are advisory, not gating. Reviewers must read them; we do not auto-approve based on Claude's output. This is by design (Principle I — humans decide).
- Cross-region diff and module blast-radius patterns produce structured but variable-length output. Cap PR comment length per the GitHub API limit (65,536 chars); chunk into multiple comments if exceeded.

---

## Alternatives Considered

**Option A: Replace Checkov + Trivy + tflint with Claude review only.** Rejected — CI gates require deterministic exit codes. Claude output is non-deterministic by design and unsuitable as a CI gate. Scanners ship 1000+ policies; Claude cannot enumerate that base of known patterns reliably on every run.

**Option B: HashiCorp Sentinel or Open Policy Agent (OPA) Rego instead of Claude review.** Rejected for two reasons: (a) Sentinel is HashiCorp-commercial and tied to Terraform Cloud — adds vendor lock-in counter to the "license-clean 2026–2030" goal in ADR-029; (b) OPA Rego authoring overhead is high for the semantic gaps Article C catalogs (the policies are not enumerable in advance — they are inferred from request-path tracing). Both tools also overlap with Checkov's coverage rather than filling the semantic gap.

**Option C: Status quo — scanners only, no semantic review layer.** Rejected — Article C's documented examples (ALB :80 returning 200, SG admin ports to `0.0.0.0/0`, Aurora missing IAM auth, Secrets Manager rotation gaps) are real failure modes our existing pipeline does not catch reliably. Audit findings during xOps-S2/S3 will surface these gaps anyway; better to catch at PR time.

**Option D: Build a custom rules engine from scratch using `terraform show -json` output + Python.** Rejected — duplicates Checkov/Trivy with a worse policy set, and the semantic gap (request-path tracing) is exactly the part that requires LLM reasoning, not a rule engine.

---

## References

- Article C: Kasaudhan, "Prompt Secure Infrastructure: The Claude Code DevSecOps Shift on AWS," devops.dev, 2026-03-10. `https://blog.devops.dev/prompt-secure-infrastructure-the-claude-code-devsecops-shift-on-aws-cf0a3ce3f264`. **Three prompt patterns and example failure modes cited; vendor blog — directional, but failure modes are independently verifiable against AWS Security Hub findings.**
- Anthropic Claude Code documentation (hooks, sub-agents, skills). `https://code.claude.com/docs/en/`.
- Anthropic Claude on AWS Bedrock — `https://docs.anthropic.com/en/api/claude-on-amazon-bedrock` (data-residency option for regulated customers).
- AWS Security Hub — managed compliance findings. `https://docs.aws.amazon.com/securityhub/latest/userguide/`.
- AWS IAM policy evaluation logic. `https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html`.
- Checkov — `https://www.checkov.io/`.
- Trivy config scanner — `https://aquasecurity.github.io/trivy/latest/docs/scanner/misconfiguration/`.
- tflint — `https://github.com/terraform-linters/tflint`.

---

## Related Decisions

| ADR | Title | Relationship |
|-----|-------|-------------|
| ADR-026 | ISO 27001 strategy | Claude review layer audits CIS v3.0.0 IaC for semantic gaps that scanners miss |
| ADR-029 | License-clean reuse policy | Skill `SKILL.md` is Apache-2.0 (matches `terraform-aws` repo license); review prompts are our local interpretation, not verbatim copy of Article C content |
| ADR-030 | SIT-only Sprint 1 scope | Skill ships in xOps-S1 (TF-03 story); production rollout follows SIT-then-UAT-then-PROD promotion path |
