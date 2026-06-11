# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

################################################################################
# ALB
################################################################################

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = try(module.alb.arn, null)
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = try(module.alb.dns_name, null)
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer (for Route 53 alias records)."
  value       = try(module.alb.zone_id, null)
}

################################################################################
# Target Groups
################################################################################

output "target_group_arns" {
  description = "Map of target group keys to their attributes (ARN, name, port, etc.)."
  value       = try(module.alb.target_groups, {})
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "ID of the ALB security group."
  value       = try(module.alb.security_group_id, null)
}

################################################################################
# Listeners
################################################################################

output "listeners" {
  description = "Map of listener keys to their attributes (ARN, port, protocol, etc.)."
  value       = try(module.alb.listeners, {})
}

################################################################################
# CloudFront
################################################################################

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = try(module.cloudfront[0].cloudfront_distribution_id, null)
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution."
  value       = try(module.cloudfront[0].cloudfront_distribution_domain_name, null)
}

################################################################################
# WAF
################################################################################

output "waf_web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL (REGIONAL scope)."
  value       = try(aws_wafv2_web_acl.this[0].arn, null)
}

output "waf_cloudfront_web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL (CLOUDFRONT scope, us-east-1)."
  value       = try(aws_wafv2_web_acl.cloudfront[0].arn, null)
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate used for CloudFront (pass-through from input)."
  value       = var.cloudfront_certificate_arn
}

################################################################################
# DNS
################################################################################

output "route53_fqdn" {
  description = "Fully qualified domain name of the Route53 record."
  value       = try(aws_route53_record.this[0].fqdn, null)
}
