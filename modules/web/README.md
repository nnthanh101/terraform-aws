# terraform-aws-web

ALB-only MVP Terraform module (RQ5a). Provisions an Application Load Balancer with HTTP-to-HTTPS redirect, an HTTPS listener backed by an ACM certificate, path-based routing rules, and an ALB security group — all inline (no upstream module wrapping).

## Usage

```hcl
module "web" {
  source = "oceansoft/terraform-aws/aws//modules/web"
  version = "~> 1.0"

  vpc_id          = "vpc-0abc123"
  subnet_ids      = ["subnet-0aaa", "subnet-0bbb"]
  certificate_arn = "arn:aws:acm:ap-southeast-2:123456789012:certificate/abc"

  target_groups = {
    app = {
      port              = 8080
      protocol          = "HTTP"
      health_check_path = "/health"
    }
  }

  listener_rules = [
    {
      priority         = 100
      path_pattern     = ["/api/*"]
      target_group_key = "app"
    }
  ]

  tags = {
    CostCenter  = "platform"
    Environment = "production"
    Project     = "web"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| aws | >= 6.28, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | VPC ID for the ALB security group | `string` | n/a | yes |
| subnet_ids | Subnet IDs (min 2, multi-AZ) | `list(string)` | n/a | yes |
| certificate_arn | ACM certificate ARN for HTTPS listener | `string` | n/a | yes |
| name | Name prefix for resources | `string` | `"web"` | no |
| target_groups | Target group definitions | `map(object)` | `{}` | no |
| listener_rules | Path-based routing rules | `list(object)` | `[]` | no |
| internal | Internal-facing ALB | `bool` | `false` | no |
| enable_deletion_protection | Prevent accidental deletion | `bool` | `false` | no |
| idle_timeout | Connection idle timeout (seconds) | `number` | `60` | no |
| create | Create resources (master toggle) | `bool` | `true` | no |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ARN of the ALB |
| alb_dns_name | DNS name of the ALB |
| alb_zone_id | Hosted zone ID of the ALB |
| target_group_arns | Map of target group ARNs keyed by name |
| security_group_id | ALB security group ID |
| http_listener_arn | HTTP listener ARN (port 80, redirects to HTTPS) |
| https_listener_arn | HTTPS listener ARN (port 443) |

## Architecture

```
Internet
    |
[ALB Security Group] (ingress 80, 443)
    |
[aws_lb] (application, multi-AZ)
    |
[aws_lb_listener: HTTP:80]  -->  HTTP 301 redirect to HTTPS
[aws_lb_listener: HTTPS:443] --> default forward / fixed-response
    |
[aws_lb_listener_rule] (path-based, for_each)
    |
[aws_lb_target_group] (for_each, IP target type)
```

## ADR References

- ADR-001: kebab-case naming
- ADR-003: Provider `>= 6.28, < 7.0`; Terraform `>= 1.11.0`
- ADR-004: 3-tier testing (snapshot / LocalStack / integration)
- ADR-005: Example prefix `mvp-`
