# ADR-029: License-Clean Reuse Policy — CC0-1.0, Apache-2.0, MIT Only

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** @cloud-architect, @security-compliance-engineer, HITL/manager
**Scope:** `github.com/nnthanh101/terraform-aws` and `github.com/1xOps/data-platform` — vendoring policy for third-party content (Terraform modules, compliance packs, scripts, documentation)
**Sprint:** xOps-S1 kickoff lock (2026-04-27); CI enforcement xOps-S2

---

## Context

The HITL kickoff frames `terraform-aws` as a "license-clean reusable IaC platform for any enterprise/startup 2026–2030." The first concrete reuse target is Resource D — Babenko's `awesome-terraform-compliance` curation list (`https://github.com/antonbabenko/awesome-terraform-compliance`). License verification at the file `LICENSE` confirms Resource D is **CC0-1.0** (public domain dedication, Creative Commons Zero v1.0 Universal). CC0-1.0 permits verbatim reuse without attribution, though attribution is recommended as good practice.

Beyond Resource D, future Sprint 1+ work will pull in:
- Compliance packs from the broader Terraform ecosystem (Compliance.tf, Prowler, Powerpipe — Resource D inventory)
- Terraform modules from the community (`psantus/s3files-sftp/aws` v0.4.0 per ADR-027, possibly cloudposse/* modules)
- DevSecOps prompt patterns (Article C, ADR-028)
- Snowflake SQL contract templates (data-platform DP-03)

Without an explicit policy, vendoring decisions accrue license debt: a single GPL or BSL dependency contaminates the downstream license posture. For a B2B Energy customer doing legal review of their software supply chain, an unvetted dependency tree is a procurement blocker.

License selection criteria for vendored content:
- **CC0-1.0** — public domain dedication; no restrictions; verbatim reuse permitted; attribution recommended but not required. Best-fit for documentation, awesome-list curation, schema templates.
- **Apache-2.0** — patent grant + attribution + `NOTICE` file requirement; copyleft-free; compatible with proprietary downstream consumers.
- **MIT** — minimal attribution-only; copyleft-free; broadly compatible.
- **GPL / AGPL** — copyleft contagion: any derivative work, including software linking against the GPL component in some interpretations, must also be GPL/AGPL. Contaminates `terraform-aws` (Apache-2.0) downstream.
- **BSL (Business Source License)** — source-available but production-restricted (typical: free for non-production use; commercial license required after a `change date`). Unsuitable for production B2B Energy deploys without negotiated commercial terms.
- **Proprietary** — explicit terms required per dependency; not acceptable as a default vendoring target.
- **No license** — under copyright law, the default for a published file with no `LICENSE` is "all rights reserved." No rights granted to consumers, even for read-only inspection. Cannot be vendored.

---

## Decision

Vendored content in `terraform-aws`, `data-platform`, and any consumer repository of the ADLC framework MUST be under **CC0-1.0, Apache-2.0, or MIT** license. **Excluded** licenses: GPL (any version), AGPL (any version), LGPL (any version), BSL, SSPL, EPL, Mozilla Public License 1.x, proprietary, no-license-stated.

Per-dependency license verification is required **before** any `git add` of vendored content. The verification artifact:
1. URL of the upstream `LICENSE` file
2. SPDX license identifier (https://spdx.org/licenses/)
3. Date of verification
4. Snapshot of the `LICENSE` file content committed alongside the vendored content (e.g., `framework/docs/awesome-terraform-compliance-curated/LICENSE-RESOURCE-D.txt`)

Verification is manual in xOps-S1 (one curated file: `framework/docs/awesome-terraform-compliance-curated.md` from Resource D, CC0-1.0). Sprint 1 ships the policy and the first verified artifact. xOps-S2 ships an automated CI gate using one of:
- **Trivy** (`trivy fs --scanners license`) — already in the `nnthanh101/terraform:slim` image per `docker-first-enforcement.md`
- **Syft + Grype** SBOM generation (CycloneDX) with license fields verified against the allow-list
- **`license-checker` npm-style** for repo-level enumeration

CI gate exit code 2 on non-allow-list licenses; CI gate writes report to `tmp/<repo>/license-audit-YYYY-MM-DD.json`.

---

## Consequences

**Positive:**

- Clean license posture for any enterprise/startup adopting `terraform-aws` 2026–2030. Customer legal review of supply chain becomes a one-page allow-list, not a per-dependency analysis.
- CC0-1.0 (Resource D) permits verbatim curation copy, halving the curation cost for compliance packs.
- Apache-2.0 alignment with `terraform-aws` repo license — no internal license-mixing surprises.
- Pre-emptive: catches GPL/BSL dependencies at vendoring time, not at customer procurement time.

**Negative / Trade-offs:**

- Excludes some high-quality compliance and security tooling (e.g., projects under MPL-2.0 like older HashiCorp packages — though current HashiCorp Terraform-related work is increasingly BSL after 2023). Workaround: cite the upstream as a reference; do not vendor.
- Manual verification in Sprint 1 is fragile. xOps-S2 CI gate is a hard-dependency for scaling. If xOps-S2 misses, manual verification continues until xOps-S3.
- LGPL excluded by precaution. LGPL technically permits dynamic linking from non-LGPL code, but Terraform module vendoring is closer to derivative-work territory than dynamic linking. Conservative exclusion.
- Snowflake-Labs/`terraform-provider-snowflake` is licensed Apache-2.0 — verified before xOps-S1 DP-03. Other Snowflake providers may differ; verify per-dependency.

---

## Alternatives Considered

**Option A: Allow GPL/AGPL vendoring.** Rejected — copyleft contagion risk. `terraform-aws` is Apache-2.0; vendoring GPL forces re-licensing or a complex compliance posture. The "any enterprise/startup 2026–2030" goal is incompatible with copyleft contagion.

**Option B: Allow only Apache-2.0 (single license).** Rejected — excludes the vast CC0-1.0 documentation/curation ecosystem and the MIT-licensed module ecosystem. Resource D itself (CC0-1.0) would be excluded — defeats the purpose of the licence-clean reuse goal.

**Option C: No license restrictions; vendor anything with a published `LICENSE`.** Rejected — legal exposure for downstream B2B Energy customers. GPL contamination is a procurement-blocker for many enterprise customers; BSL is a production-blocker. Pre-emptive exclusion is cheaper than per-customer remediation.

**Option D: Allow MPL-2.0 (Mozilla Public License 2.0).** Rejected for Sprint 1 — MPL-2.0 is file-level copyleft (modifications to MPL files must be MPL, but MPL files can sit alongside Apache-2.0/MIT in a project). Defensible position, but the vendoring boundary is harder to enforce in CI than a pure copyleft-free allow-list. Reserve MPL-2.0 reconsideration for xOps-S5 retrospective.

**Option E: Per-customer license waiver (allow GPL with customer-side legal review).** Rejected — destroys the "single allow-list" simplicity. Each customer engagement becomes a bespoke license review.

---

## References

- Resource D: Babenko, `awesome-terraform-compliance`, GitHub. `https://github.com/antonbabenko/awesome-terraform-compliance`. **License: CC0-1.0** (verified at `https://github.com/antonbabenko/awesome-terraform-compliance/blob/master/LICENSE` on 2026-04-26).
- SPDX License List — `https://spdx.org/licenses/`. **Authoritative source for SPDX identifiers.**
- CC0-1.0 — Creative Commons Zero v1.0 Universal — `https://creativecommons.org/publicdomain/zero/1.0/`.
- Apache License 2.0 — `https://www.apache.org/licenses/LICENSE-2.0`.
- MIT License — `https://opensource.org/license/mit/`.
- GPL contagion analysis — Free Software Foundation, GPL FAQ — `https://www.gnu.org/licenses/gpl-faq.html`.
- BSL (Business Source License 1.1) — `https://mariadb.com/bsl11/`.
- Trivy license scanner — `https://aquasecurity.github.io/trivy/latest/docs/scanner/license/`.
- CycloneDX SBOM specification — `https://cyclonedx.org/specification/overview/`.
- Snowflake-Labs `terraform-provider-snowflake` license — `https://github.com/Snowflake-Labs/terraform-provider-snowflake/blob/main/LICENSE` (Apache-2.0).
- HashiCorp Terraform license history (post-2023 BSL transition) — `https://www.hashicorp.com/license-faq`.

---

## Related Decisions

| ADR | Title | Relationship |
|-----|-------|-------------|
| ADR-026 | ISO 27001 strategy | License-clean dependencies feed CIS v3.0.0 module composition |
| ADR-027 | SFTP → S3 Files migration | License check on `psantus/s3files-sftp/aws` v0.4.0 required before xOps-S2 adoption decision |
| ADR-028 | Claude Code DevSecOps adoption | Skill `SKILL.md` authored as Apache-2.0 internal content; not a verbatim copy of Article C |
| ADR-030 | SIT-only Sprint 1 scope | License verification automated CI gate scheduled for xOps-S2 (post-Sprint-1) |
