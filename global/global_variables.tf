# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# SSOT: Tag Taxonomy + Shared Variable Conventions for terraform-aws module library (KISS/LEAN)
#
# This file is the SINGLE SOURCE OF TRUTH for:
#   - Tag taxonomy (5-tier: Application-Anchor / Mandatory / FinOps / Compliance / Ops)
#   - Shared variable names, types, and validation rules
#
# USAGE RULES:
#   - Modules CANNOT import variables from this file (Terraform has no cross-module variable import).
#   - Root compositions (accounts/, projects/, examples/, tests/) copy the tag structure from here.
#   - Any tag name change MUST be made here first, then propagated to all consumers.
#   - Do NOT convert this file into a module — it is a convention document, not a resource factory.
#
# Tag Taxonomy (TO-BE, 5-tier — F1-S6d):
#
#   Tier 0 — Application Anchor (AWS-managed, AppRegistry):
#     awsApplication  = <app ARN>    AWS-managed key injected by AppRegistry at RESOURCE level.
#                                    Pattern: merge({ Service = "..." }, var.additional_tags)
#                                    where additional_tags = try(module.appregistry.application_tag, {})
#                                    in the consuming root (infra/terraform-aws/dev/main.tf).
#                                    Source: terraform-aws/modules/appregistry/outputs.tf
#                                    NEVER placed in provider.default_tags — Terraform evaluates
#                                    provider config statically at plan time; injecting a module
#                                    output there creates a cycle and breaks planning.
#                                    FOCUS 1.2 mapping: SubAccountId (application boundary)
#                                    CSDM mapping: Application (Level 4 — bounded context)
#                                    Do NOT hand-code this value; always obtain from AppRegistry output.
#
#   Tier 1 — Mandatory (enforced by AWS Organizations Tag Policy + SCP):
#     Environment     = dev|staging|prod|sandbox|test|sit|uat|preprod|dr
#                                    FOCUS 1.2: Environment dimension
#                                    CSDM: Environment Classification
#     Owner           = <email>      Incident contact; maps to FOCUS 1.2 Tag (OwnerEmail)
#     CostCenter      = <string>     FinOps showback/chargeback unit; FOCUS 1.2: CostCenter
#     ManagedBy       = Terraform    IaC provenance; CSDM: Provisioned By
#
#   Tier 2 — FinOps / CSDM (FOCUS 1.2+ dimension mapping):
#     ServiceName     = <string>     Microservice or logical grouping within the application
#                                    FOCUS 1.2: ServiceName dimension
#                                    CSDM: Technical Service
#     ServiceCategory = <string>     AWS service category (Compute, Storage, Database, Network…)
#                                    FOCUS 1.2: ServiceCategory dimension (maps to aws:servicecategory)
#                                    CSDM: Service Classification
#     BusinessUnit    = <string>     Business unit or product line owning this resource
#                                    FOCUS 1.2: SubAccountName (organisational boundary)
#                                    CSDM: Business Unit
#
#   Tier 3 — Compliance (APRA CPS 234 Para 15):
#     DataClassification = public|internal|confidential|restricted
#                                    APRA CPS 234 Para 15 information asset classification
#                                    CSDM: Data Classification
#     Compliance      = none|apra-cps234|pci-dss|iso27001|soc2
#                                    Applicable compliance frameworks; multiple values comma-separated
#                                    CSDM: Compliance Framework
#
#   Tier 4 — Operational:
#     Name            = <string>     Human-readable resource name for console / CLI display
#                                    AWS convention: set on every named resource
#     BackupPolicy    = none|default|daily-7d|daily-30d|daily-90d
#                                    RPO bucket; maps to AWS Backup plan selection tag
#                                    CSDM: Recovery Policy
#     GitRepo         = <string>     Source repository for IaC traceability
#                                    CSDM: Configuration Item — Source

# ---------------------------------------------------------------------------
# FOCUS 1.2 Column + CSDM Concept Mapping (Tag-SSOT reconciliation)
# ---------------------------------------------------------------------------
# This block maps every SSOT tag key to its FOCUS 1.2 column and CSDM concept.
# Three categories: static provider.default_tags (8 keys) | resource-level only
# (awsApplication via additional_tags) | per-resource context (non-module tags).
#
# Key                | FOCUS 1.2 Column       | CSDM Concept               | Where set
# -------------------|------------------------|----------------------------|------------------
# Application        | ServiceName            | Technical Service          | provider.default_tags (modules/tags)
# Service            | ServiceCategory        | Service Classification     | provider.default_tags (modules/tags)
# Environment        | Environment            | Environment Classification  | provider.default_tags (modules/tags)
# Owner              | Tags[OwnerEmail]       | Owner                      | provider.default_tags (modules/tags)
# CostCenter         | CostCenter             | Cost Center                | provider.default_tags (modules/tags)
# ManagedBy          | Tags[ProvisionedBy]    | Provisioned By             | provider.default_tags (modules/tags)
# Compliance         | Tags[Compliance]       | Compliance Framework       | provider.default_tags (modules/tags)
# DataClassification | Tags[DataClass]        | Data Classification        | provider.default_tags (modules/tags)
# awsApplication     | SubAccountId           | Application Service        | RESOURCE level only — var.additional_tags (NEVER provider.default_tags: cycle)
# BusinessUnit       | SubAccountName         | Business Unit              | Per-module locals or per-account root
# Name               | (display only)         | (AWS console name)         | Per-resource (AWS convention)
# BackupPolicy       | Tags[BackupPolicy]     | Recovery Policy            | Per-resource context
# GitRepo            | Tags[GitRepo]          | CI Source                  | Per-resource context
#
# Naming relationship: modules/tags input `application` (var.application = service name string)
# maps to the SSOT "ServiceName" concept and is exposed as the "Application" tag key.
# This is DISTINCT from SSOT Tier 0 "awsApplication" (AppRegistry ARN injected via additional_tags).
# The "Application" tag key identifies the workload; "awsApplication" is the AppRegistry link.
#
# Mandatory FOCUS tags (must be non-empty at plan time — enforced by modules/tags precondition):
#   Application, Service, Environment, Owner, CostCenter, ManagedBy, Compliance, DataClassification
# ---------------------------------------------------------------------------

variable "project_name" {
  description = "Project identifier for resource tagging and state key paths"
  type        = string
  default     = "terraform-aws"
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be: dev, staging, or prod."
  }
}

variable "region" {
  description = "Primary AWS region (ap-southeast-2). Identity Center uses us-east-1."
  type        = string
  default     = "ap-southeast-2"
  validation {
    condition     = can(regex("^(ap-southeast-2|us-east-1)$", var.region))
    error_message = "Must be ap-southeast-2 (primary) or us-east-1 (Identity Center)."
  }
}

variable "owner" {
  description = "Resource owner email for accountability and incident contact"
  type        = string
  default     = "platform-team@example.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Must be a valid email address."
  }
}

variable "cost_center" {
  description = "Cost allocation unit for FinOps showback/chargeback (maps to CostCenter tag)"
  type        = string
  default     = "platform"
}

variable "data_classification" {
  description = "Data sensitivity level per APRA CPS 234 Para 15 (information asset classification)"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Must be: public, internal, confidential, or restricted."
  }
}

variable "default_tags_enabled" {
  description = "Enable default tags on all resources via provider default_tags block"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Tags applied to all resources — 5-tier taxonomy for FOCUS 1.2+ FinOps, APRA CPS 234 compliance, and AppRegistry application anchor (F1-S6d)"
  type        = map(string)
  default = {
    # Tier 0 — Application Anchor (awsApplication is AWS-managed / injected by AppRegistry)
    # Do NOT set awsApplication here. It is propagated at RESOURCE level via additional_tags
    # (merge into each resource tags{} block), NOT in provider.default_tags (cycle risk).
    # See: infra/terraform-aws/dev/main.tf and terraform-aws/modules/appregistry/outputs.tf

    # Tier 1 — Mandatory (enforced by AWS Organizations Tag Policy + SCP)
    # FOCUS 1.2 mapping: Environment, CostCenter, Owner(Email), ManagedBy(ProvisionedBy)
    # CSDM mapping: Environment Classification, Cost Center, Owner, Provisioned By
    Project     = "terraform-aws"
    Environment = "dev"
    Owner       = "platform-team@example.com"
    CostCenter  = "platform"
    ManagedBy   = "Terraform"

    # Tier 2 — FinOps / CSDM (FOCUS 1.2+ dimension mapping)
    # ServiceName and ServiceCategory set per-module in locals.tf (context-specific values).
    # BusinessUnit set per-module or per-account (maps to FOCUS 1.2 SubAccountName / CSDM BU).
    ServiceName     = "platform"
    ServiceCategory = "Management"
    BusinessUnit    = "platform"

    # Tier 3 — Compliance (APRA CPS 234 Para 15)
    # CSDM: Data Classification, Compliance Framework
    DataClassification = "internal"
    Compliance         = "none"

    # Tier 4 — Operational
    # BackupPolicy RPO buckets: none | default | daily-7d | daily-30d | daily-90d
    # CSDM: Recovery Policy, Configuration Item — Source
    BackupPolicy = "default"
    GitRepo      = "terraform-aws"
  }
}
