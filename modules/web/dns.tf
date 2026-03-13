# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Route53 DNS records — A record alias to CloudFront (or ALB if CF disabled).

resource "aws_route53_record" "this" {
  count = var.create && var.create_dns ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = local.dns_target_name
    zone_id                = local.dns_target_zone_id
    evaluate_target_health = true
  }
}
