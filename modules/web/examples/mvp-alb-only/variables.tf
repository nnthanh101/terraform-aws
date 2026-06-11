# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

variable "vpc_id" {
  description = "ID of the VPC in which to create the ALB security group."
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs (min 2, different AZs) to attach to the ALB."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener."
  type        = string
}
