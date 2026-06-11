# ADR-030: Sprint 1 Environment Scope — SIT Only

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** @cloud-architect, @product-owner, @delivery-manager, HITL/manager
**Scope:** `github.com/nnthanh101/terraform-aws` and `github.com/1xOps/data-platform` — environment provisioning scope for xOps-S1 (2026-04-27 → 2026-05-03)
**Sprint:** xOps-S1 kickoff lock (2026-04-27)

---

## Context

The HITL Day-1 kickoff request enumerates approximately 28 work items spanning environments (SIT, UAT, Pre-Prod, PROD), vendor integrations (UIQ, NGP, BC API Gateway, BC NGP, Diverge), governance (CAB approvals, user-role audits, emergency-access procedures, file-path validation, CAB sign-off chains), pipelines (release pipelines, parallel run, cutovers), and ML stack (MLflow, feature store evaluation). All of this in week 1 (2026-04-27 → 2026-05-03).

Capacity check using INVEST `Estimable` and `Small` heuristics:

| Scope dimension | Sprint 1 if all-in | Sprint 1 SIT-only |
|---|---|---|
| Environments | 4 (SIT, UAT, Pre-Prod, PROD) | 1 (SIT) |
| Vendor integrations | 5 active (UIQ, NGP, BC×2, Diverge) | 0 (deferred) |
| Governance artifacts | CAB workflow + access audit + emergency-access + file-path validation | 0 (deferred to S4) |
| ML stack | MLflow + feature store eval + dbt | 0 (deferred to S2/S3) |
| Module new code | All ISO 27001 modules + S3 Files implementation + Claude DevSecOps + ML | 1 module (`cloudtrail-cmk`) + 1 skill (`iac-security-review`) + scaffold for `s3files-staging` |
| Story points | 50+ SP estimated | 25 SP across 7 stories |

A 50+ SP load in week 1 is a guaranteed `THIN_STORY_INFLATION` violation — every story would lack acceptance criteria depth, evidence, or testable outcomes. Sprint 1 of a multi-quarter Modern Data Platform engagement is the wrong sprint to attempt full-stack delivery — Sprint 1's job is to prove the ADLC loop end-to-end with a single working slice, then scale.

The SIT-only scope is also a learning safeguard. SIT is the first environment to provision; the lessons learned (Terraform state layout, IAM design, CAB-process integration, evidence wiring) inform UAT/Pre-Prod/PROD provisioning. Doing SIT alone in Sprint 1 produces a battle-tested template; doing 4 environments in parallel produces 4 untested templates with shared bugs.

The HITL kickoff items are not dropped — every one is mapped to a target sprint (xOps-S2 through xOps-S5) with named dependencies in the approved `/Users/nnthanh/.claude/plans/this-session-aims-to-rustling-catmull.md` Day-1 deferred-items table.

---

## Decision

Sprint 1 (xOps-S1, 2026-04-27 → 2026-05-03) environment scope is **SIT only** in both `terraform-aws` and `data-platform` repositories. UAT, Pre-Prod, and PROD environments are deferred:

| Environment | Target Sprint | Dependency |
|---|---|---|
| SIT | xOps-S1 (this sprint) | Sprint 1 deliverable |
| UAT | xOps-S2 (2026-05-04+) | SIT modules battle-tested in xOps-S1 |
| Pre-Prod | xOps-S3 | UAT promotion-path validated |
| PROD | xOps-S4 | CAB approval + parallel run + go-live cutover plan |

Sprint 1 deliverables in `terraform-aws`:
- 1 new module: `modules/cloudtrail-cmk` (CIS v3.0.0 first slice per ADR-026), tested against `aws-sandbox` SIT account
- 1 module scaffold: `modules/s3files-staging/README.md` (no `.tf` code; per ADR-027)
- 1 new skill: `.claude/skills/security/iac-security-review/SKILL.md` (per ADR-028)
- 5 ADRs: ADR-026 through ADR-030 (this set)
- 1 license-clean curation: `framework/docs/awesome-terraform-compliance-curated.md` (CC0-1.0 vendored, per ADR-029)

Sprint 1 deliverables in `data-platform`:
- Submodule `adlc-framework` consumption + onboarding verification
- Meter-360 Data Product Canvas (McKinsey ch.25 6S — Scoping/Selecting/Structuring only; Sourcing/Sharing/Steering deferred)
- Snowflake SIT schema (`DP_SIT.METERING.METER_DIM`, `METER_READING_FACT`) consuming `terraform-aws/s3` v2.2.1 + `terraform-aws/kms` v2.2.1
- 100-row PII-free fixture + Great Expectations DQ suite
- FOCUS 1.2+ tagging on all SIT-provisioned resources

Out of scope for Sprint 1 (mapped per the plan deferred-items table):
- ISO 27001 controls beyond `cloudtrail-cmk` (Config, Security Hub, GuardDuty → xOps-S2; Inspector, Access Analyzer, IAM Identity Center hardening → xOps-S3)
- `s3files-staging` actual `.tf` implementation (xOps-S2, gated on HashiCorp PR #47325 merge)
- SFTP module deprecation (xOps-S4+)
- Snowflake `STORAGE INTEGRATION`, bulk-load tooling, seed meters across envs (xOps-S2)
- UIQ / NGP / BC / Diverge / SFTP-on-prem integrations (xOps-S3+; depend on vendor procurement)
- UAT, Pre-Prod, PROD environment builds (xOps-S2/S3/S4)
- CAB approvals, parallel-run, cutover, support model (xOps-S4 PROD readiness)
- MLflow, feature store evaluation (xOps-S2/S3, gated on first model use case)
- Federated governance + CDO + data council (xOps-S5, post-data-pods + post-pipes per McKinsey ch.27)

---

## Consequences

**Positive:**

- Sprint 1 is achievable: 25 SP across 7 stories in 5 working days (3.5–5 SP/day), within fresh-team capacity (25–30 SP).
- Modules ship battle-tested in SIT before promotion. The Terraform state layout, IAM design, evidence wiring, and CAB-integration patterns are validated once before being replicated across UAT/Pre-Prod/PROD.
- Sprint 1 retrospective surfaces concrete data (DORA DF/LT/CFR/MTTR with N=1 baseline) for Sprint 2 capacity planning.
- The producer-consumer split (`terraform-aws` ships, `data-platform` composes) is proven on one slice — the model for any future industry rollout 2026–2030.

**Negative / Trade-offs:**

- HITL stakeholders expecting "Modern Data Platform live" in week 1 may experience expectation mismatch. Mitigation: the deferred-items table in the approved plan names every kickoff item with a target sprint and dependency — communicate clearly at Mon `/ceremony:plan` and again at the Friday `/ceremony:review`.
- UIQ/NGP/BC/Diverge integrations require multi-week vendor cert/credential procurement. Sprint 1 scope-out gives time to start procurement in parallel without blocking Sprint 1 delivery.
- PROD CAB workflow is xOps-S4 — 3 sprints away. Customer-facing roadmaps must reflect this; do not commit to PROD dates inside Sprint 1.
- "SIT only" can be misread as "SIT forever." This ADR's deferral table is the antidote — every kickoff item has a target sprint, not a "later TBD."

---

## Alternatives Considered

**Option A: SIT + UAT in Sprint 1.** Rejected — doubles infrastructure story count to ~12 SP, displacing the data-platform Snowflake schema (DP-03) and the Meter-360 canvas (DP-02). The producer-consumer split would not be proven on the data product side, weakening the "ADLC loop end-to-end" success criterion. UAT promotion-path also requires SIT lessons; doing both in parallel duplicates errors.

**Option B: PROD-first MVP (skip SIT/UAT/Pre-Prod, ship straight to PROD).** Rejected — no CAB process exists yet (kickoff item, deferred to xOps-S4); regulatory exposure for B2B Energy customers; no parallel-run validation mechanism. Violates Principle I (Acceptable Agency — humans decide on production changes); violates ADLC governance (PROD = HITL-only operations).

**Option C: Local-only / no SIT (Docker Compose for Snowflake mock; LocalStack for AWS).** Rejected — does not validate cloud module composition (the producer-consumer split needs real `terraform-aws` v2.2.1 modules consumed in real cloud). Also fails the Sprint 1 success criterion 3 ("Snowflake SIT live" — DP-03).

**Option D: 4-environment parallel build (SIT + UAT + Pre-Prod + PROD all in Sprint 1).** Rejected — 50+ SP load. Guaranteed `THIN_STORY_INFLATION` and `RUBBER_STAMP_COORDINATION` violations.

**Option E: SIT-only but defer Snowflake schema (DP-03) to Sprint 2 — IaC only in Sprint 1.** Considered. Rejected — fails Sprint 1 success criterion 4 ("ADLC loop closed" requires producer + consumer evidence). DP-03 is the consumer that proves `terraform-aws` v2.2.1 modules are truly consumable; without it, Sprint 1 is IaC-only, breaking the end-to-end loop premise.

---

## References

- Approved plan: `/Users/nnthanh/.claude/plans/this-session-aims-to-rustling-catmull.md` (HITL-approved 2026-04-26 via ExitPlanMode). Day-1 deferred-items table maps every HITL kickoff item to xOps-S2 through xOps-S5.
- McKinsey & Company, *Rewired: The McKinsey Guide to Outcompeting in the Age of Digital and AI* (2023), Section 5, chapter 25 "Data Product Pod operating model" (6S framework: Scoping, Selecting, Structuring, Sourcing, Sharing, Steering). PDF at `/Volumes/Working/projects/adlc-framework/knowledge/rewired-the-mckinsey-guide/rewired-the-mckinsey-guide-section5.pdf`.
- INVEST framework — Independent, Negotiable, Valuable, Estimable, Small, Testable. Bill Wake, 2003. `https://www.agilealliance.org/glossary/invest/`.
- Atlassian Scrum Guide — sprint-length guidance ("one month or less"). `https://www.atlassian.com/agile/scrum`.
- ADLC governance — `framework/retrospectives/` and `.claude/rules/governance/adlc-governance.md` for sprint-cadence rationale.
- Anti-pattern catalog — `THIN_STORY_INFLATION`, `RUBBER_STAMP_COORDINATION`, `PREMATURE_ABSTRACTION`, `LAZY_DEFERRAL` in `.claude/rules/governance/anti-patterns-catalog.md`.

---

## Related Decisions

| ADR | Title | Relationship |
|-----|-------|-------------|
| ADR-026 | ISO 27001 strategy | This ADR constrains the first CIS v3.0.0 slice to SIT only |
| ADR-027 | SFTP → S3 Files migration | This ADR's deliverable for ADR-027 is scaffold-only (no `.tf`) — consistent with SIT-only deferral |
| ADR-028 | Claude Code DevSecOps adoption | Skill ships in Sprint 1; production rollout follows SIT → UAT → PROD path |
| ADR-029 | License-clean reuse policy | Manual verification in Sprint 1; CI gate deferred to xOps-S2 |
