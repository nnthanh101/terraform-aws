# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

variable "account_id" {
  description = "AWS account ID. Defaults to auto-detect via aws_caller_identity."
  type        = string
  default     = null
}

variable "region" {
  description = "AWS region where ECS resources are deployed."
  type        = string
  default     = "ap-southeast-2"
}

variable "vpc_id" {
  description = "VPC ID for ECS service security group. HITL-supplied at init time — no default."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for Fargate task placement. HITL-supplied at init time — no default."
  type        = list(string)
}

variable "default_tags" {
  description = "APRA CPS 234 required tags. Must include CostCenter and DataClassification."
  type        = map(string)
  default = {
    CostCenter         = "platform"
    Project            = "ecs"
    Environment        = "sandbox"
    ServiceName        = "ecs"
    DataClassification = "internal"
    ManagedBy          = "terraform"
    Owner              = "platform-team"
    Team               = "cloudops"
  }
}
