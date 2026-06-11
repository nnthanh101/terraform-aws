# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

locals {
  # Merge caller tags with a module-level Name tag for easy identification
  common_tags = merge(
    { Name = var.name },
    var.tags,
  )

  # DNS target: CloudFront domain if enabled, otherwise ALB DNS name
  dns_target_name    = var.create_cloudfront ? try(module.cloudfront[0].cloudfront_distribution_domain_name, "") : try(module.alb.dns_name, "")
  dns_target_zone_id = var.create_cloudfront ? try(module.cloudfront[0].cloudfront_distribution_hosted_zone_id, "") : try(module.alb.zone_id, "")
}
