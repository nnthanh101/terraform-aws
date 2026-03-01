# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

variable "account_id" {
  description = "AWS account ID for Identity Center assignments. Defaults to auto-detect via aws_caller_identity."
  type        = string
  default     = null
}

variable "sso_region" {
  description = "AWS region for IAM Identity Center (global endpoint). Defaults to us-east-1."
  type        = string
  default     = "us-east-1"
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
