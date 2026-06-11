# terraform-aws-web

CloudFront + WAFv2 (dual scope) + ALB + ACM + Route53 Terraform module.
Provides HTTPS ingress with DDoS protection and WebSocket passthrough for the xOps sovereign AI chatbot.

## Features

- ALB (application) with multi-AZ, TLS 1.3, HTTP-to-HTTPS redirect
- CloudFront distribution with ALB origin, CachingOptimized default behavior
- Dual WAFv2 scope: REGIONAL (ALB) + CLOUDFRONT (us-east-1 provider alias)
- AWS Managed Rule Groups: CommonRuleSet, KnownBadInputsRuleSet, BotControlRuleSet (REGIONAL)
- WebSocket cache bypass for configurable path patterns (`/ws/*`, `/socket.io/*`)
- Route53 DNS A record alias pointing to CloudFront (or ALB when CloudFront is disabled)
- ALB sticky sessions (`lb_cookie`, configurable duration) via pass-through `target_groups`
- APRA CPS 234 compliant: encrypted transport (TLS 1.2+ minimum), WAF DDoS protection

## Architecture

```
Internet
    |
    +---> [WAFv2 CLOUDFRONT (us-east-1)]
    |
[CloudFront Distribution]  (PriceClass_100, TLS 1.2 minimum)
    |   default behavior  -->  CachingOptimized
    |   /ws/* /socket.io/*  -->  CachingDisabled (WebSocket passthrough)
    |
    +---> [WAFv2 REGIONAL (ALB)]
    |
[ALB Security Group] (ingress 80, 443)
    |
[aws_lb] (application, multi-AZ)
    |-- [Listener HTTP:80]   --> HTTP 301 redirect to HTTPS
    |-- [Listener HTTPS:443] --> TLS 1.3 (ELBSecurityPolicy-TLS13-1-2-2021-06)
    |
[aws_lb_target_group] (for_each, IP target type, optional lb_cookie sticky)
    |
[Route53 A alias] --> CloudFront domain (or ALB fallback)
```

## Usage

### Full example — CloudFront + dual WAF + WebSocket + DNS + sticky sessions

```hcl
module "web" {
  source  = "oceansoft/terraform-aws/aws//modules/web"
  version = "~> 1.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name       = "mvp-web"
  vpc_id     = "vpc-0abc123"
  subnet_ids = ["subnet-0aaa", "subnet-0bbb", "subnet-0ccc"]

  # ALB listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/alb-cert"
      forward = {
        target_group_key = "app"
      }
    }
  }

  # Target groups with sticky sessions (AC8)
  target_groups = {
    app = {
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"
      create_attachment = false
      health_check = {
        enabled = true
        path    = "/health"
      }
      stickiness = {
        enabled         = true
        type            = "lb_cookie"
        cookie_duration = 86400
      }
    }
  }

  # CloudFront
  create_cloudfront          = true
  cloudfront_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/cf-cert"
  cloudfront_aliases         = ["app.example.com"]
  cloudfront_price_class     = "PriceClass_100"

  # WAF — dual scope
  create_waf            = true
  create_waf_cloudfront = true

  # WebSocket passthrough (CachingDisabled behavior)
  websocket_paths = ["/ws/*", "/socket.io/*"]

  # Route53 DNS
  create_dns       = true
  domain_name      = "app.example.com"
  route53_zone_id  = "Z1234567890ABC"

  tags = {
    CostCenter  = "platform"
    Environment = "production"
    Project     = "xops"
  }
}
```

### Minimal example — ALB only (no CloudFront, no WAF)

```hcl
module "web" {
  source  = "oceansoft/terraform-aws/aws//modules/web"
  version = "~> 1.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name       = "mvp-web"
  vpc_id     = "vpc-0abc123"
  subnet_ids = ["subnet-0aaa", "subnet-0bbb"]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/alb-cert"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      protocol    = "HTTP"
      port        = 8080
      target_type = "ip"
      health_check = {
        enabled = true
        path    = "/health"
      }
    }
  }

  tags = { Environment = "dev", Project = "xops" }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| aws | >= 6.28, < 7.0 |

Note: The `aws.us_east_1` provider alias is always required in the calling module (used for WAFv2 CLOUDFRONT scope and ACM certificate lookup). When `create_cloudfront = false` and `create_waf_cloudfront = false`, the alias is declared but no resources are created in us-east-1.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create` | Master toggle — set to `false` to skip all resource creation | `bool` | `true` | no |
| `name` | Name prefix for all resources (max 32 chars, ALB limit) | `string` | `"web"` | no |
| `tags` | Additional tags merged with module common_tags | `map(string)` | `{}` | no |
| `vpc_id` | VPC ID for the ALB security group | `string` | n/a | yes |
| `subnet_ids` | Subnet IDs (min 2, different AZs) | `list(string)` | n/a | yes |
| `internal` | If true, ALB is internal (not internet-facing) | `bool` | `false` | no |
| `enable_deletion_protection` | Prevent accidental ALB deletion via AWS API | `bool` | `false` | no |
| `idle_timeout` | ALB connection idle timeout in seconds | `number` | `60` | no |
| `security_group_ingress_rules` | ALB security group ingress rules (pass-through to upstream module) | `any` | HTTP+HTTPS from `0.0.0.0/0` | no |
| `security_group_egress_rules` | ALB security group egress rules (pass-through to upstream module) | `any` | all outbound | no |
| `listeners` | ALB listener configurations (pass-through to upstream ALB module) | `any` | `{}` | no |
| `target_groups` | ALB target group configurations including optional `stickiness` block | `any` | `{}` | no |
| `associate_web_acl` | Associate an existing WAF Web ACL ARN with the ALB | `bool` | `false` | no |
| `web_acl_arn` | ARN of an existing WAF Web ACL (used when `associate_web_acl = true`) | `string` | `null` | no |
| `create_cloudfront` | Create a CloudFront distribution in front of the ALB | `bool` | `false` | no |
| `cloudfront_certificate_arn` | ACM certificate ARN in us-east-1 for CloudFront | `string` | `null` | no |
| `cloudfront_aliases` | Domain aliases for the CloudFront distribution | `list(string)` | `[]` | no |
| `cloudfront_price_class` | CloudFront price class (`PriceClass_100`, `PriceClass_200`, `PriceClass_All`) | `string` | `"PriceClass_100"` | no |
| `cloudfront_wait_for_deployment` | Wait for CloudFront distribution to fully deploy | `bool` | `false` | no |
| `create_waf` | Create WAFv2 Web ACL (REGIONAL scope) and associate with ALB | `bool` | `false` | no |
| `create_waf_cloudfront` | Create WAFv2 Web ACL (CLOUDFRONT scope, us-east-1) and associate with CloudFront | `bool` | `false` | no |
| `websocket_paths` | Path patterns that bypass CloudFront caching (WebSocket endpoints) | `list(string)` | `[]` | no |
| `create_dns` | Create Route53 A record alias for the domain | `bool` | `false` | no |
| `domain_name` | FQDN for the Route53 record (e.g., `app.example.com`) | `string` | `null` | no |
| `route53_zone_id` | Route53 hosted zone ID for DNS record creation | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alb_arn` | ARN of the Application Load Balancer |
| `alb_dns_name` | DNS name of the Application Load Balancer |
| `alb_zone_id` | Canonical hosted zone ID of the ALB (for Route53 alias records) |
| `target_group_arns` | Map of target group keys to their full attributes (ARN, name, port, etc.) |
| `security_group_id` | ID of the ALB security group |
| `listeners` | Map of listener keys to their full attributes (ARN, port, protocol, etc.) |
| `cloudfront_distribution_id` | ID of the CloudFront distribution (`null` when `create_cloudfront = false`) |
| `cloudfront_domain_name` | Domain name of the CloudFront distribution (`null` when `create_cloudfront = false`) |
| `waf_web_acl_arn` | ARN of the WAFv2 Web ACL — REGIONAL scope (`null` when `create_waf = false`) |
| `waf_cloudfront_web_acl_arn` | ARN of the WAFv2 Web ACL — CLOUDFRONT scope (`null` when `create_waf_cloudfront = false`) |
| `acm_certificate_arn` | ACM certificate ARN used for CloudFront (pass-through from `cloudfront_certificate_arn`) |
| `route53_fqdn` | FQDN of the Route53 record (`null` when `create_dns = false`) |

## WAF Managed Rule Groups

### REGIONAL scope (ALB) — `create_waf = true`

| Rule Group | Priority | Action |
|------------|----------|--------|
| `AWSManagedRulesCommonRuleSet` | 10 | Block |
| `AWSManagedRulesKnownBadInputsRuleSet` | 20 | Block |
| `AWSManagedRulesBotControlRuleSet` | 30 | Block |

### CLOUDFRONT scope (us-east-1) — `create_waf_cloudfront = true`

| Rule Group | Priority | Action |
|------------|----------|--------|
| `AWSManagedRulesCommonRuleSet` | 10 | Block |
| `AWSManagedRulesKnownBadInputsRuleSet` | 20 | Block |

## WebSocket Support

When `websocket_paths` is set, CloudFront creates additional cache behaviors for each path using the `CachingDisabled` managed cache policy. This allows WebSocket upgrade requests to pass through to the ALB without caching interference.

Default paths for xOps chatbot:

```hcl
websocket_paths = ["/ws/*", "/socket.io/*"]
```

## ADR References

- ADR-001: kebab-case naming convention for all resources
- ADR-003: Provider constraints `>= 6.28, < 7.0`; Terraform `>= 1.11.0`
- ADR-004: 3-tier testing (snapshot / LocalStack / AWS sandbox integration)
- ADR-005: Example name prefix `mvp-`
