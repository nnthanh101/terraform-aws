# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

variable "account_id" {
  description = "AWS account ID for Identity Center assignments. Defaults to auto-detect via aws_caller_identity."
  type        = string
  default     = null
}

variable "security_account_id" {
  description = "AWS account ID of the dedicated security/audit account. Optional — omit for single-account sandbox deployments."
  type        = string
  default     = null
}

variable "workload_account_id" {
  description = "AWS account ID of the primary workload account. Optional — omit for single-account sandbox deployments."
  type        = string
  default     = null
}

variable "sso_region" {
  description = "AWS region where IAM Identity Center is enabled."
  type        = string
  default     = "ap-southeast-2"
}

variable "default_tags" {
  description = "Default tags applied to all resources via provider. Override per environment/account in tfvars."
  type        = map(string)
  default = {
    CostCenter         = "platform"
    Project            = "iam-identity-center"
    Environment        = "sandbox"
    ServiceName        = "sso"
    DataClassification = "internal"
    ManagedBy          = "terraform"
  }
}
