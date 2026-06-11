# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# WAFv2 Web ACL — CLOUDFRONT scope (us-east-1) for CloudFront distribution.
# Requires aws.us_east_1 provider alias passed via configuration_aliases.

resource "aws_wafv2_web_acl" "cloudfront" {
  count    = var.create && var.create_waf_cloudfront ? 1 : 0
  provider = aws.us_east_1

  name        = "${var.name}-cf-waf"
  description = "WAF Web ACL (CLOUDFRONT) for ${var.name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-cf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-cf-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-cf-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, var.tags)
}
