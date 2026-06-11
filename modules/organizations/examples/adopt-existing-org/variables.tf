# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.
#
# Variables for adopt-existing-org reference root.
# SSOT: global/global_variables.tf — tag taxonomy, naming conventions.
# Replace all placeholder values before running terraform plan.

variable "aws_region" {
  description = "AWS region for the provider. Organizations API is global but the provider still requires a region. Replace <your-aws-region> in your tfvars file."
  type        = string
  default     = "us-east-1"
}

# ---------------------------------------------------------------------------
# Tag variables — copied from global/global_variables.tf (modules cannot import).
# ---------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment for tag compliance."
  type        = string
  default     = "sandbox"

  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox", "test"], var.environment)
    error_message = "Must be: dev, staging, prod, sandbox, or test."
  }
}

variable "cost_center" {
  description = "Cost allocation unit for FinOps showback/chargeback (maps to CostCenter tag)."
  type        = string
  default     = "platform"
}

variable "owner" {
  description = "Resource owner email for incident contact and tag compliance."
  type        = string
  default     = "platform-team@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner))
    error_message = "Must be a valid email address."
  }
}
