# FOCUS 1.2+ tag schema variables.
# 8-tag taxonomy: Application, Service, Environment, Owner, CostCenter,
#                 ManagedBy (auto-set to "terraform"), Compliance, DataClassification.
#
# References:
#   https://focus.finops.org/focus-specification/
#   https://aws.amazon.com/blogs/mt/tag-your-aws-resources-for-cost-allocation-with-aws-myapplications/

variable "environment" {
  type        = string
  description = "Deployment environment. Allowed: dev, staging, prod, sandbox, dr."
  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox", "dr"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, sandbox, dr."
  }
}

variable "application" {
  type        = string
  description = "Application name for FOCUS ServiceName rollup and AppRegistry correlation key."
  default     = "my-application"
}

variable "service" {
  type        = string
  description = "Component enum for FOCUS group-by axis. Allowed: backend, storefront, data, edge, async."
  default     = "backend"
  validation {
    condition     = contains(["backend", "storefront", "data", "edge", "async"], var.service)
    error_message = "service must be one of: backend, storefront, data, edge, async."
  }
}

variable "owner" {
  type        = string
  description = "Owning team email or slug. Maps to FOCUS Owner / cmdb_ci.support_group."
  default     = "team@example.com"
}

variable "cost_center" {
  type        = string
  description = "Finance cost center code. Pattern: CC-XXXXXXX (alphanumeric, 4-16 chars). Maps to FOCUS BilledCost rollup."
  default     = "CC-PLATFORM-001"
  validation {
    condition     = can(regex("^CC-[A-Z0-9][A-Z0-9_-]{2,14}$", var.cost_center))
    error_message = "cost_center must start with 'CC-' followed by 3-15 uppercase alphanumeric/dash/underscore characters (e.g. CC-PLATFORM-001 or CC-0042)."
  }
}

variable "compliance" {
  type        = string
  description = "Applicable compliance framework. Maps to sn_grc control scope."
  default     = "n/a"
  validation {
    condition     = contains(["n/a", "soc2", "apra-cps234", "gdpr"], var.compliance)
    error_message = "compliance must be one of: n/a, soc2, apra-cps234, gdpr."
  }
}

variable "data_classification" {
  type        = string
  description = "Data sensitivity tier. Maps to CSDM Information Object / APRA data-asset."
  default     = "internal"
  validation {
    condition     = contains(["internal", "customer", "pii"], var.data_classification)
    error_message = "data_classification must be one of: internal, customer, pii."
  }
}
