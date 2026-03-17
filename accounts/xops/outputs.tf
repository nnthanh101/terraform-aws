# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Output pass-through from composed modules.

################################################################################
# ECS
################################################################################

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = module.ecs.cluster_arn
}

output "services" {
  description = "Map of ECS services and their attributes."
  value       = module.ecs.services
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for ECS tasks."
  value       = module.ecs.cloudwatch_log_group_name
}

output "task_exec_iam_role_arn" {
  description = "Task execution IAM role ARN (for Secrets Manager + ECR access)."
  value       = module.ecs.task_exec_iam_role_arn
}

################################################################################
# Web (ALB + CloudFront + WAFv2)
################################################################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = module.web.alb_dns_name
}

output "security_group_id" {
  description = "ID of the ALB security group."
  value       = module.web.security_group_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.web.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.web.cloudfront_domain_name
}

output "waf_web_acl_arn" {
  description = "WAFv2 Web ACL ARN (REGIONAL scope)."
  value       = module.web.waf_web_acl_arn
}

output "route53_fqdn" {
  description = "Route53 fully qualified domain name."
  value       = module.web.route53_fqdn
}

output "xops_endpoint" {
  description = "xOps access URL (CloudFront if enabled, otherwise ALB)."
  value       = "https://${coalesce(module.web.cloudfront_domain_name, module.web.alb_dns_name)}"
}

################################################################################
# EFS
################################################################################

output "efs_file_system_id" {
  description = "EFS file system ID."
  value       = module.efs.id
}

output "efs_access_points" {
  description = "Map of EFS access points and their attributes."
  value       = module.efs.access_points
}

################################################################################
# KMS
################################################################################

output "kms_key_arn" {
  description = "KMS key ARN used for EFS encryption."
  value       = module.kms_efs.key_arn
}
