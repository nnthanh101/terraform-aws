# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = local.oidc_provider_arn
}

output "plan_role_arn" {
  description = "ARN of the plan/readonly IAM role (trusted from any ref)."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "ARN of the apply IAM role (trusted from main branch only)."
  value       = aws_iam_role.apply.arn
}

output "plan_role_name" {
  description = "Name of the plan/readonly IAM role."
  value       = aws_iam_role.plan.name
}

output "apply_role_name" {
  description = "Name of the apply IAM role."
  value       = aws_iam_role.apply.name
}
