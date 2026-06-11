# ADR-026: ISO 27001 Strategy — CIS AWS Foundations Benchmark v3.0.0 as Practical Proxy

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** @cloud-architect, @security-compliance-engineer, HITL/manager
**Scope:** `github.com/nnthanh101/terraform-aws` ISO 27001 baseline IaC roadmap (xOps-S1 through xOps-S3)
**Sprint:** xOps-S1 kickoff lock (2026-04-27)

---

## Context

The HITL kickoff for the Modern Data Platform (B2B Energy/Metering on Snowflake, 2026–2030) names ISO 27001 as the audit framework. The original ask is "land an ISO 27001 baseline in `terraform-aws` Sprint 1." A literal Annex A enumeration in IaC is consultancy-grade scope — Annex A has 93 controls (ISO/IEC 27001:2022) covering organizational, people, physical, and technological domains, the majority of which are policy and process artifacts not Terraform resources. Sprint 1 capacity is one ISO 27001 module (5 SP).

Article A (Kuzminskyi, infrahouse, 2026-03-28, `https://infrahouse.com/blog/2026-03-28-iso-27001-on-aws/`) — directional only, vendor blog — confirms that infrahouse uses **CIS AWS Foundations Benchmark v3.0.0** as the practical implementation proxy because:
- Annex A enumeration is consultancy-grade (mapping each control to AWS-specific evidence is bespoke work)
- CIS v3.0.0 is implementable as IaC controls (each control maps to one or more `aws_*` resources)
- AWS Security Hub natively supports CIS AWS Foundations Benchmark v3.0.0 as a compliance standard, producing audit findings without bespoke control wiring (primary source: `https://docs.aws.amazon.com/securityhub/latest/userguide/cis-aws-foundations-benchmark.html`)

This ADR locks the strategy: ISO 27001 is the audit framework; CIS v3.0.0 is the IaC implementation proxy. The phased roadmap is sequenced so Sprint 1 ships a single, fully-tested control slice rather than a thin layer across many controls.

---

## Decision

ISO 27001 is the audit framework reported to stakeholders and auditors. The IaC implementation proxy is **CIS AWS Foundations Benchmark v3.0.0**. Each `terraform-aws` security/compliance module maps each `aws_*` resource to one or more CIS v3.0.0 control IDs in its `README.md` resource-to-control table.

The phased roadmap:

| Sprint | Module | CIS v3.0.0 Control Set (illustrative) |
|---|---|---|
| **xOps-S1** | `cloudtrail-cmk` | 3.x (Logging) — multi-region trail with customer-managed KMS key separation |
| **xOps-S2** | `aws-config`, `security-hub-aggregator`, `guardduty` | 1.x/2.x (IAM/Storage), 4.x (Monitoring) |
| **xOps-S3** | `inspector`, `access-analyzer`, `iam-identity-center-hardening` | 1.x (IAM advanced), 5.x (Networking hardening) |

Sprint 1 (xOps-S1) ships **only** `cloudtrail-cmk` as the first ISO 27001 / CIS v3.0.0 baseline slice. It proves the producer-consumer split (`terraform-aws` ships, `data-platform` and other consumers compose) and the resource-to-control mapping convention before scaling.

Vendor-blog claims (Article A) are directional. Primary authoritative sources for control implementation are AWS Security Hub CIS v3.0.0 standard documentation and CIS AWS Foundations Benchmark v3.0.0 itself (Center for Internet Security, `https://www.cisecurity.org/benchmark/amazon_web_services`).

---

## Consequences

**Positive:**

- Every control becomes a Terraform module with a CIS-control-ID-to-resource map in module `README.md` — auditable evidence, not narrative.
- `Article A`-cited "evidence is the Terraform files; revocation history is in Git" thesis is materialized: the Git log of `modules/cloudtrail-cmk/` is the audit trail for that control.
- AWS Security Hub natively reports CIS v3.0.0 findings — auditors consume the same data the platform team consumes (no bespoke reporting layer).
- Phased delivery means each sprint ships a working control slice; we do not block Sprint 1 on full Annex A enumeration.

**Negative / Trade-offs:**

- Auditors expecting full Annex A coverage will need a control-mapping artifact in xOps-S2 or xOps-S3 (`docs/compliance/iso-27001-annex-a-to-cis-v3.md`) — not in scope for Sprint 1.
- CIS v3.0.0 covers AWS technical controls only. Annex A organizational and people controls (background checks, awareness training, supplier relationships) are out of scope for this IaC roadmap and remain HITL/manager responsibility.
- Locking on CIS v3.0.0 means Security Hub will need a re-baseline if/when CIS publishes v4.0.0 — quantify in xOps-S5+ retrospective.

---

## Alternatives Considered

**Option A: Full ISO 27001 Annex A enumeration in IaC (Sprint 1).** Rejected — consultancy-grade scope, blocks Sprint 1 delivery. 93 controls × 1 sprint = guaranteed `THIN_STORY_INFLATION` and `PREMATURE_ABSTRACTION` violations. The majority of Annex A controls (organizational, people, physical) are policy artifacts, not `aws_*` resources.

**Option B: NIST 800-53 as IaC implementation framework.** Rejected — FedRAMP-oriented; less aligned with B2B Energy/Metering customers (commercial sector ISO 27001 is the dominant audit framework). NIST 800-53 has ~1000 controls vs CIS v3.0.0's ~50 — even larger scope-bloat risk.

**Option C: SOC 2 Type II first.** Rejected — SOC 2 is audit-firm-driven (each big-four firm publishes its own control mapping), not IaC-driven. SOC 2 trust services criteria do not map cleanly to AWS resource-level controls without a control-mapping consultancy engagement. ISO 27001 + CIS v3.0.0 is the cleaner IaC-first path.

**Option D: AWS Foundational Security Best Practices (FSBP) instead of CIS v3.0.0.** Rejected — FSBP is AWS-published and AWS-auditor-friendly but is a superset that includes preview/beta service checks. CIS v3.0.0 is industry-standard, multi-cloud-portable in spirit (CIS publishes equivalent benchmarks for Azure, GCP) — better fit for "any enterprise/startup 2026–2030" reuse goal.

---

## References

- McKinsey & Company, *Rewired: The McKinsey Guide to Outcompeting in the Age of Digital and AI* (2023), Section 5 "Embedding Data Everywhere," chapter 24 "What Data Matters Most." PDF at `/Volumes/Working/projects/adlc-framework/knowledge/rewired-the-mckinsey-guide/rewired-the-mckinsey-guide-section5.pdf`.
- Article A: Kuzminskyi, "ISO 27001 on AWS," infrahouse.com, 2026-03-28. `https://infrahouse.com/blog/2026-03-28-iso-27001-on-aws/`. **Directional only — vendor blog.**
- AWS Security Hub — CIS AWS Foundations Benchmark v3.0.0 standard. `https://docs.aws.amazon.com/securityhub/latest/userguide/cis-aws-foundations-benchmark.html`. **Primary authoritative source.**
- AWS Config — operational compliance evaluation. `https://docs.aws.amazon.com/config/latest/developerguide/`.
- AWS CloudTrail — audit log architecture. `https://docs.aws.amazon.com/awscloudtrail/latest/userguide/`.
- Center for Internet Security — CIS AWS Foundations Benchmark. `https://www.cisecurity.org/benchmark/amazon_web_services`.
- ISO/IEC 27001:2022 — Information security management systems requirements (purchased standard, not URL-linkable).
- Anthropic Claude Code documentation — `https://code.claude.com/docs/en/`.

---

## Related Decisions

| ADR | Title | Relationship |
|-----|-------|-------------|
| ADR-027 | SFTP → S3 Files migration plan | Independent; both contribute to Sprint 1 IaC roadmap |
| ADR-028 | Claude Code DevSecOps adoption | Complementary — Claude review layer audits CIS v3.0.0 IaC for semantic gaps scanners miss |
| ADR-029 | License-clean reuse policy | Governs vendoring of CIS-aligned compliance packs (e.g., awesome-terraform-compliance, CC0-1.0) |
| ADR-030 | SIT-only Sprint 1 scope | Constrains the first CIS slice (`cloudtrail-cmk`) to SIT only |
