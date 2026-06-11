# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# CloudFront distribution wrapping oceansoft/cloudfront/aws module.

module "cloudfront" {
  source = "../cloudfront"

  count = var.create && var.create_cloudfront ? 1 : 0

  create = true

  aliases = var.cloudfront_aliases

  comment             = "${var.name} CloudFront distribution"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  wait_for_deployment = var.cloudfront_wait_for_deployment

  default_cache_behavior = {
    target_origin_id         = "alb"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
  }

  # WebSocket cache bypass — CachingDisabled policy for real-time paths
  ordered_cache_behavior = [
    for path in var.websocket_paths : {
      path_pattern             = path
      target_origin_id         = "alb"
      viewer_protocol_policy   = "https-only"
      allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = false
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
    }
  ]

  web_acl_id = var.create_waf_cloudfront ? try(aws_wafv2_web_acl.cloudfront[0].arn, null) : null

  origin = {
    alb = {
      domain_name = module.alb.dns_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  viewer_certificate = {
    acm_certificate_arn      = var.cloudfront_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2025"
  }

  tags = merge(local.common_tags, var.tags)
}
