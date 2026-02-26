# ADR-008: Tag Governance — Enterprise + FOCUS 1.2+ Co-existence Strategy

- **Status**: Proposed
- **Date**: 2026-02-27
- **Deciders**: HITL/Manager, Product Owner, Cloud Architect
- **Supersedes**: ADR-XVAL-005 (advisory finding — Owner/Repository gap)

## What

Maintain two parallel tagging systems on all Terraform-managed AWS resources:
1. **Enterprise tags** (PascalCase) — organizational taxonomy feeding CMDB, ServiceNow, and AWS Cost Explorer
2. **FOCUS 1.2+ tags** (snake_case prefixed `x_`) — cross-cloud FinOps allocation per FOCUS specification

Add the two missing APRA-mandated Enterprise tags (`Owner` and `Repository`) to `projects/iam-identity-center/versions.tf` `default_tags`.

## Why

### Tag System Comparison

| Attribute | Enterprise Tags | FOCUS 1.2+ Tags |
|-----------|----------------|-----------------|
| Key format | PascalCase (`CostCenter`) | snake_case with prefix (`x_cost_center`) |
| Consumed by | AWS Cost Explorer, ServiceNow CMDB, CloudTrail, APRA auditors | FinOps dashboards, cross-cloud cost tooling, FOCUS-compliant exporters |
| Granularity | Organizational (repo-level `Project`) | Workload-level (`x_project = "iam-identity-center"`) |
| Overlap | `CostCenter = "platform"` | `x_cost_center = "platform"` (same value, different system) |
| Intentional divergence | `Project = "terraform-aws"` (repo identity) | `x_project = "iam-identity-center"` (workload identity) |
| Required by | APRA CPS 234, enterprise CMDB contract | FOCUS 1.2+ specification |

### Why `Project != x_project` (correct by design)

`Project = "terraform-aws"` identifies the IaC repository (all modules in this repo share it).
`x_project = "iam-identity-center"` identifies the billable workload (FOCUS SubProduct concept).
These serve different consumers: enterprise CMDB tracks the repository unit; FinOps dashboards
track workload spend. Aligning them to the same value would corrupt FOCUS cost attribution.

### Why `CostCenter` and `x_cost_center` co-exist

This is a transition architecture. Enterprise tags predate FOCUS adoption. Removing `CostCenter`
would break CMDB integrations. Adding `x_cost_center` enables FOCUS tooling without migration.
When the organization completes FOCUS migration, `CostCenter` may be deprecated (future ADR).

### Why `Owner` and `Repository` are required

APRA CPS 234 Para 15 requires asset inventory with accountability. The ADLC template (ADR-XVAL-005)
identified these as missing from `projects/iam-identity-center/versions.tf`. They are not enforced
by `CKV_APRA_001` (which only checks `data_classification` on `aws_ssoadmin_permission_set`),
but they ARE required by the organizational APRA tagging template and CMDB contract.

## Who

- **HITL/Manager**: Approves tag governance policy
- **Cloud Architect**: Designs co-existence strategy (this ADR)
- **Infrastructure Engineer**: Applies `Owner` + `Repository` tags to `versions.tf`

## When

| Action | Owner | Sprint |
|--------|-------|--------|
| ADR-008 proposed | Cloud Architect | Sprint 2 |
| versions.tf updated with Owner + Repository | Infrastructure Engineer | Sprint 2 |
| ADR-008 accepted by HITL | HITL | Sprint 2 |
| FOCUS migration assessment (future) | Product Owner | Sprint 5+ |

## Where

- Primary change: `projects/iam-identity-center/versions.tf` `provider "aws" { default_tags {} }`
- Secondary: `modules/iam-identity-center/` resources inherit via `default_tags` + `merge()` pattern
- Checkov: `.checkov/custom_checks/check_apra_cps234.py` (CKV_APRA_001) and `check_focus_tags.py` (CKV_CUSTOM_FOCUS_001)

## How

### Target Tag Block (versions.tf)

```hcl
provider "aws" {
  region = "ap-southeast-2"

  default_tags {
    tags = {
      # ── Enterprise Tags (PascalCase) ─────────────────────────────────────
      # Consumed by: AWS Cost Explorer, ServiceNow CMDB, APRA CPS 234 audits
      # Scope: repository-level (all modules in terraform-aws share these)
      Project     = "terraform-aws"         # IaC repository identity (NOT workload)
      Environment = "sandbox"
      CostCenter  = "platform"              # Organizational cost centre (CMDB)
      Owner       = "nnthanh101@gmail.com"  # APRA Para 15: accountable individual/team
      Repository  = "https://github.com/nnthanh101/terraform-aws"  # APRA asset registry
      Compliance  = "APRA-CPS234"
      ManagedBy   = "terraform"

      # ── APRA CPS 234 Additional ──────────────────────────────────────────
      # Para 15: Data classification required on all information assets
      data_classification = "internal"

      # ── FOCUS 1.2+ Tags (snake_case, x_ prefix) ──────────────────────────
      # Consumed by: FinOps dashboards, cross-cloud cost exporters
      # Scope: workload-level (intentionally different granularity from Enterprise)
      # NOTE: x_cost_center intentionally mirrors CostCenter during FOCUS transition
      # NOTE: x_project != Project by design (workload != repository)
      x_cost_center  = "platform"           # FOCUS BillingAccountId allocation
      x_environment  = "sandbox"            # FOCUS EnvironmentName
      x_project      = "iam-identity-center"  # FOCUS SubProductName (workload, not repo)
      x_service_name = "sso"               # FOCUS ServiceName
    }
  }
}
```

### Checkov Compliance

| Check | ID | Enforces | Satisfied by |
|-------|----|---------|--------------|
| APRA data classification | CKV_APRA_001 | `data_classification` on `aws_ssoadmin_permission_set` | `data_classification = "internal"` in default_tags -> merges to all resources |
| APRA least privilege | CKV_APRA_002 | No AdministratorAccess | No change from this ADR |
| APRA session duration | CKV_APRA_003 | Session <= 8h | No change from this ADR |
| FOCUS 1.2+ tags | CKV_CUSTOM_FOCUS_001 | 4 x_ tags on taggable resources | All 4 x_ tags present in default_tags |

`Owner` and `Repository` have no current checkov enforcement. Documented here for APRA
Para 15 accountability traceability. A future `CKV_APRA_004` check may enforce them.

## Consequences

### Benefits
1. No breaking changes to existing CMDB integrations (Enterprise tags retained)
2. FOCUS 1.2+ tooling can ingest correctly-scoped workload tags immediately
3. `x_project` correctly identifies workload spend independent of repository structure
4. APRA Para 15 accountability gap closed (`Owner`, `Repository` added)
5. Inline comments make the co-existence rationale durable in the codebase

### Tradeoffs
1. 11-tag block is verbose — mitigated by inline comments grouping the two systems
2. `CostCenter` and `x_cost_center` carry identical values during transition — acceptable duplication

### Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Future engineer removes `x_cost_center` assuming it duplicates `CostCenter` | Medium | Medium | Inline comments + this ADR explain the necessity |
| FOCUS spec updates require additional x_ tags | Low | Low | ADR review cycle at each FOCUS spec minor version |
| APRA auditor requires `CKV_APRA_004` for Owner/Repository | Low | Medium | Tags are already present; adding a check is non-breaking |

## Alternatives Considered

1. **Single merged tag set** (normalize to FOCUS only): Rejected — breaks existing CMDB contract; CMDB expects PascalCase keys
2. **Remove FOCUS tags from default_tags, apply per-resource**: Rejected — increases maintenance surface; default_tags is the right DRY pattern
3. **Rename `x_project` to match `Project`**: Rejected — corrupts FOCUS SubProduct/workload attribution

## Related ADRs

- [ADR-007: Upstream dependency strategy](./ADR-007-upstream-dependency-strategy.md)
- ADR-XVAL-005 (ephemeral, superseded by this ADR)

## Coordination Evidence

- Product Owner log: `tmp/terraform-aws/coordination-logs/product-owner-2026-02-27.json`
- Cloud Architect log: `tmp/terraform-aws/coordination-logs/cloud-architect-2026-02-27-adr-cost-tags.json`
