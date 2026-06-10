# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# SSOT: Tag Taxonomy + Shared Variable Conventions for terraform-aws module library (KISS/LEAN)
#
# This file is the SINGLE SOURCE OF TRUTH for:
#   - Tag taxonomy (4-tier: Mandatory / FinOps / Compliance / Ops)
#   - Shared variable names, types, and validation rules
#
# USAGE RULES:
#   - Modules CANNOT import variables from this file (Terraform has no cross-module variable import).
#   - Root compositions (accounts/, projects/, examples/, tests/) copy the tag structure from here.
#   - Any tag name change MUST be made here first, then propagated to all consumers.
#   - Do NOT convert this file into a module — it is a convention document, not a resource factory.
#
# Tag Taxonomy (4-tier):
#   Tier 1 — Mandatory:  Project, Environment, Owner, CostCenter, ManagedBy
#   Tier 2 — FinOps:     ServiceName, ServiceCategory (FOCUS 1.2+)
#   Tier 3 — Compliance: DataClassification, Compliance (APRA CPS 234)
#   Tier 4 — Ops:        Automation, BackupPolicy, GitRepo

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
  description = "Tags applied to all resources — 4-tier taxonomy for FOCUS 1.2+ FinOps and APRA CPS 234 compliance"
  type        = map(string)
  default = {
    # Tier 1 — Mandatory (enforced by AWS Organizations Tag Policy)
    Project     = "terraform-aws"
    Environment = "dev"
    Owner       = "platform-team@example.com"
    CostCenter  = "platform"
    ManagedBy   = "Terraform"

    # Tier 2 — FinOps (FOCUS 1.2+ dimension mapping)
    # ServiceName and ServiceCategory set per-module in locals.tf

    # Tier 3 — Compliance (APRA CPS 234)
    DataClassification = "internal"
    Compliance         = "none"

    # Tier 4 — Operational
    Automation   = "true"
    BackupPolicy = "default"
    GitRepo      = "terraform-aws"
  }
}
