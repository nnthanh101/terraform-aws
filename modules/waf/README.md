# AWS WAFv2 Terraform Module

Terraform module to create and manage AWS WAFv2 Web ACLs, rules, and IP sets.

> Derived from [cloudposse/terraform-aws-waf](https://github.com/cloudposse/terraform-aws-waf) (Apache-2.0). See [NOTICE.txt](NOTICE.txt).

## Usage

```hcl
module "waf" {
  source = "github.com/nnthanh101/terraform-aws//modules/waf?ref=v2.0.0"

  name                  = "my-waf"
  scope                 = "REGIONAL"
  association_resource_arns = [module.alb.arn]

  managed_rule_group_statement_rules = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        sampled_requests_enabled   = true
        metric_name                = "common-rules"
      }
    }
  ]

  tags = {
    CostCenter  = "platform"
    Environment = "production"
  }
}
```

## Features

- AWS Managed Rule Groups (CommonRuleSet, KnownBadInputs, SQLi, XSS)
- IP set rules (allowlist/blocklist)
- Rate-based rules
- Geo-match rules
- Custom rules with regex patterns
- Size constraint rules
- REGIONAL and CLOUDFRONT scopes
- ALB/API Gateway/AppSync association

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| aws | >= 6.28, < 7.0 |

## Inputs

See [variables.tf](variables.tf) for full input reference.

## Outputs

See [outputs.tf](outputs.tf) for full output reference.

## License

Apache-2.0. See [LICENSE](../../LICENSE).
