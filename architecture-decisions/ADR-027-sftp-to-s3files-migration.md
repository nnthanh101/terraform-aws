# ADR-027: SFTP → S3 Files Migration Plan

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** @cloud-architect, @solutions-architect, HITL/manager
**Scope:** Deprecation roadmap for `terraform-aws/modules/sftp` (currently shipping at v2.2.1) and introduction of `modules/s3files-staging` bridge module
**Sprint:** xOps-S1 kickoff lock (2026-04-27); execution xOps-S2+

---

## Context

The `terraform-aws` repository currently ships an `sftp` module at v2.2.1 wrapping AWS Transfer Family. AWS Transfer Family carries a baseline cost of approximately $216/month per endpoint per Article B's worked example: $0.30/hour endpoint × 720 hours = $216/month before per-GB transfer charges (`$0.04/GB`). Article B (Santus, dev.to/aws-builders, 2026-04-08, `https://dev.to/aws-builders/aws-s3-files-just-made-transfer-family-sftp-obsolete-for-most-use-cases-4me`) reports that for the same use case, AWS S3 Files (preview) + Fargate-hosted SFTP front-end runs at approximately $25/month: NLB ~$16 + Fargate 0.25 vCPU / 512 MB ~$9. That is an 88% reduction (`($216 − $25) / $216 = 88.4%`). All cost figures cited from Article B's worked example; not measured in our environment.

The data-platform consumer (Snowflake-anchored Meter-360 product) needs an S3 staging bucket that Snowflake's `STORAGE INTEGRATION` consumes directly. If the same bucket is the SFTP staging destination, the SFTP-to-S3 hop is eliminated entirely — the customer SFTP client writes to the same bucket Snowflake reads from. This is the architectural motivation: not just cost reduction but elimination of an unnecessary staging hop.

**Critical caveat from Article B:** HashiCorp `terraform-provider-aws` PR #47325 — adding the `aws_s3files_file_system` resource — is **not yet merged at the time of writing** (verify at `https://github.com/hashicorp/terraform-provider-aws/pulls`). Until merge, the only Terraform path is `psantus/s3files-sftp/aws` v0.4.0 published by Article B's author (an AWS Community Builder, not HashiCorp). This is an early-access AWS feature with no SLA, and a community module with single-author maintenance risk.

Sprint 1 must lock the migration plan without committing to early-access dependencies in production. Sprint 1 deliverable for this ADR is a `modules/s3files-staging/README.md` scaffold only (no `.tf` code) with a TODO referencing PR #47325 — deferring actual implementation to xOps-S2 once the merge status is known.

---

## Decision

Lock the three-phase migration plan:

1. **xOps-S1 (this sprint):** Document the migration in this ADR. Ship `modules/s3files-staging/README.md` scaffold (no `.tf` code) with a TODO block referencing HashiCorp PR #47325 and the `psantus/s3files-sftp/aws` v0.4.0 bridge. Existing `modules/sftp` remains at v2.2.1 — no deprecation marker yet.
2. **xOps-S2:** Decision gate — has PR #47325 merged? **If yes**, implement `modules/s3files-staging/` using native `aws_s3files_file_system` resource. **If no**, implement using `psantus/s3files-sftp/aws` v0.4.0 as a bridge module dependency, with a follow-up story to migrate to native once PR #47325 lands.
3. **xOps-S4 (or later):** Once `s3files-staging` is proven in 1+ consumer (data-platform Meter-360), tag `terraform-aws/sftp` v3.0.0 with a deprecation notice in module `README.md`. No code removal yet — give downstream consumers two minor versions to migrate. Snowflake `STORAGE INTEGRATION` consuming the same S3 bucket is documented as the canonical pattern in `data-platform`.

The decision **does not** commit Sprint 1 to early-access AWS features in production. It commits Sprint 1 only to the scaffold + plan, deferring the `.tf` implementation choice to xOps-S2 when more PR-merge data is available.

---

## Consequences

**Positive:**

- 88% cost reduction documented (cited from Article B; not yet measured in our environment).
- Cleaner producer-consumer architecture: customer SFTP writes to the same S3 bucket Snowflake reads from — one less staging hop.
- Decision is locked; no relitigation in xOps-S2 retrospectives. The PR-merge gate produces a binary outcome (native vs. bridge), not a re-decision.

**Negative / Trade-offs:**

- HashiCorp PR #47325 timing is uncertain. If it does not merge by xOps-S2 start (2026-05-04), we either accept early-access risk (`psantus/s3files-sftp/aws` v0.4.0 bridge) or push native implementation to xOps-S3.
- `psantus/s3files-sftp/aws` v0.4.0 is single-author / Community-Builder-published — no SLA, possible rate limits or breaking changes between minor versions. If chosen, document it as a temporary bridge in `modules/s3files-staging/README.md`.
- AWS S3 Files itself is in preview at the time of writing — pricing model may change before GA. Article B's $25/month figure is illustrative.
- Bridge-module debt accrues until PR #47325 merges and we migrate. Monthly review of PR status during xOps-S2/S3 retros.

---

## Alternatives Considered

**Option A: Keep AWS Transfer Family indefinitely.** Rejected — $216/month baseline cost is roughly 8.6× the S3 Files + Fargate alternative per Article B. For a B2B Energy customer onboarding (Sprint 1 ships SIT only, but production rollout is the multi-year target), this compounds across every customer environment.

**Option B: Fork HashiCorp `terraform-provider-aws` to apply PR #47325 ourselves.** Rejected — provider fork carries indefinite maintenance burden (rebase against upstream every minor release). Unsuitable for "license-clean reuse 2026–2030" goal.

**Option C: Use `psantus/s3files-sftp/aws` v0.4.0 in production now (xOps-S1).** Rejected — early-access AWS feature, no AWS SLA, single-author community module. xOps-S2 bridge gives time to observe PR #47325 merge progress and reduce risk. The scaffold-only Sprint 1 deliverable preserves optionality.

**Option D: Skip S3 Files entirely; use S3 + customer-side `aws s3 cp` over IAM credentials.** Rejected — many B2B Energy customers' provisioning systems are SFTP-only (legacy on-prem schedulers); replacing SFTP wholesale is a customer-procurement question, not an IaC decision. S3 Files preserves the SFTP wire protocol.

---

## References

- Article B: Santus, "AWS S3 Files just made Transfer Family SFTP obsolete for most use cases," dev.to/aws-builders, 2026-04-08. `https://dev.to/aws-builders/aws-s3-files-just-made-transfer-family-sftp-obsolete-for-most-use-cases-4me`. **Cost data and IAM model cited; vendor blog by AWS Community Builder — directional but technical content is verifiable against AWS documentation.**
- HashiCorp `terraform-provider-aws` PR #47325 — `aws_s3files_file_system` resource. `https://github.com/hashicorp/terraform-provider-aws/pulls` (filter by 47325). **Merge status to be verified before each sprint planning ceremony.**
- AWS Transfer Family pricing — `https://aws.amazon.com/aws-transfer-family/pricing/`.
- AWS S3 Files (preview) documentation — `https://docs.aws.amazon.com/AmazonS3/` (preview content; URL stable post-GA).
- `psantus/s3files-sftp/aws` v0.4.0 — Terraform Registry: `https://registry.terraform.io/modules/psantus/s3files-sftp/aws`. License: verify before adoption per ADR-029.
- Snowflake S3 Storage Integration — `https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration`.
- HashiCorp Terraform Registry — `https://registry.terraform.io/providers/hashicorp/aws`.

---

## Related Decisions

| ADR | Title | Relationship |
|-----|-------|-------------|
| ADR-026 | ISO 27001 strategy | Independent; both Sprint 1 IaC roadmap items |
| ADR-029 | License-clean reuse policy | Governs license check on `psantus/s3files-sftp/aws` v0.4.0 before adoption |
| ADR-030 | SIT-only Sprint 1 scope | This ADR's Sprint 1 deliverable (scaffold only) is consistent with SIT-only constraint |
