# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Input variables for xOps account composition (KMS + EFS + ECS + Web).

################################################################################
# Core
################################################################################

variable "region" {
  description = "AWS region for xOps deployment."
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming and tagging."
  type        = string
  default     = "xops"
}

################################################################################
# Network (HITL-supplied at init/apply time)
################################################################################

variable "vpc_id" {
  description = "VPC ID for ECS, EFS, and ALB resources. HITL-supplied."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB placement. At least 2 AZs required."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least 2 public subnet IDs required for ALB multi-AZ."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks and EFS mount targets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs required for ECS/EFS multi-AZ."
  }
}

################################################################################
# ECS Container
################################################################################

variable "container_image" {
  description = "Docker image URI for the xOps API container."
  type        = string
}

variable "container_port" {
  description = "Port exposed by the xOps API container."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU)."
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Number of ECS tasks to run."
  type        = number
  default     = 1
}

################################################################################
# Domain & TLS (HITL-supplied)
################################################################################

variable "domain_name" {
  description = "Fully qualified domain name (e.g., xops.oceansoft.io). Set null to skip DNS."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS record creation."
  type        = string
  default     = null
}

variable "cloudfront_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront. Required when create_cloudfront = true."
  type        = string
  default     = null
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN in deployment region for ALB HTTPS listener."
  type        = string
  default     = null
}

################################################################################
# Feature flags
################################################################################

variable "create_cloudfront" {
  description = "Create CloudFront distribution in front of ALB."
  type        = bool
  default     = true
}

variable "create_waf" {
  description = "Create WAFv2 Web ACL (REGIONAL scope) for ALB."
  type        = bool
  default     = true
}

variable "create_waf_cloudfront" {
  description = "Create WAFv2 Web ACL (CLOUDFRONT scope, us-east-1) for CloudFront."
  type        = bool
  default     = true
}

################################################################################
# Secrets
################################################################################

variable "secrets_arns" {
  description = "Map of environment variable name to Secrets Manager ARN for ECS task secrets."
  type        = map(string)
  default     = {}
}

################################################################################
# Tags (APRA CPS 234 + FOCUS 1.2+)
################################################################################

variable "default_tags" {
  description = "Default tags applied to all resources. Must include CostCenter and DataClassification (enforced by modules/ecs)."
  type        = map(string)
  default = {
    CostCenter         = "xops"
    Project            = "xops"
    Environment        = "dev"
    DataClassification = "internal"
    ManagedBy          = "terraform"
    Owner              = "platform-engineering@oceansoft.io"
    Compliance         = "APRA-CPS234"
  }
}
