# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

output "alb_dns_name" {
  description = "DNS name of the ALB. Use this as the value for a Route 53 alias record."
  value       = module.web.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = module.web.alb_arn
}

output "target_group_arns" {
  description = "Map of target group keys to their attributes."
  value       = module.web.target_group_arns
}

output "security_group_id" {
  description = "ID of the ALB security group. Use in service security group ingress rules."
  value       = module.web.security_group_id
}

output "listeners" {
  description = "Map of listener keys to their attributes."
  value       = module.web.listeners
}
