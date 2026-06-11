# FOCUS 1.2+ tag composition — generic SSOT for all AWS workload tags.
#
# TAG TAXONOMY (4-tier):
#   Tier 1 — Mandatory:  Application, Environment, Owner, CostCenter, ManagedBy
#   Tier 2 — FinOps:     Service (FOCUS 1.2 ServiceName+ServiceCategory composite)
#   Tier 3 — Compliance: DataClassification, Compliance (APRA CPS 234 / SOC2 / GDPR)
#   Tier 4 — Ops:        (ManagedBy in Tier 1; BackupPolicy/GitRepo added at resource level)
#
# Cross-cutting Service convention:
#   - State/cross-cutting resources:  Service = backend (catch-all)
#   - SQS/SNS messaging:              Service = async
#   - Media/CDN assets:               Service = storefront
#   These are per-resource `tags {}` overrides; this block sets the root default.
#
# Refs:
#   https://focus.finops.org/focus-specification/
#   https://aws.amazon.com/blogs/mt/tag-your-aws-resources-for-cost-allocation-with-aws-myapplications/
#   https://developer.hashicorp.com/terraform/language/values/locals

locals {
  common_tags = {
    # FOCUS ServiceName → AppRegistry rollup key.
    Application = var.application

    # FOCUS group-by axis — enum: backend|storefront|data|edge|async.
    Service = var.service

    # Deployment environment.
    Environment = var.environment

    # Owning team for incident and cost escalation.
    Owner = var.owner

    # Finance chargeback (subsumes BillingTag per FOCUS BilledCost rollup).
    CostCenter = var.cost_center

    # IaC traceability.
    ManagedBy = "terraform"

    # CSDM sn_grc control scope.
    Compliance = var.compliance

    # CSDM Information Object / APRA data-asset classification.
    DataClassification = var.data_classification
  }
}
