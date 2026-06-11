# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

################################################################################
# Module toggle
################################################################################

variable "create" {
  description = "Determines whether resources will be created (affects all resources)."
  type        = bool
  default     = true
}

################################################################################
# Naming & tagging
################################################################################

variable "name" {
  description = "Name prefix applied to the ALB and associated resources. Maximum 32 characters (AWS ALB limit)."
  type        = string
  default     = "web"
}

variable "tags" {
  description = "A map of additional tags to merge with the module common_tags and apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Networking
################################################################################

variable "vpc_id" {
  description = "ID of the VPC in which the ALB security group will be created."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach to the ALB. At least 2 subnets in different Availability Zones are required for multi-AZ redundancy."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided to satisfy ALB multi-AZ requirements."
  }
}

variable "internal" {
  description = "If true, the ALB will be internal (not internet-facing)."
  type        = bool
  default     = false
}

################################################################################
# ALB settings
################################################################################

variable "enable_deletion_protection" {
  description = "If true, deletion of the ALB will be disabled via the AWS API. Upstream module defaults to true; this module defaults to false for developer-friendly environments. Set to true for production."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "The time in seconds that the connection can be idle before the ALB closes it."
  type        = number
  default     = 60
}

################################################################################
# Security group rules
################################################################################

variable "security_group_ingress_rules" {
  description = "Map of ingress rule definitions passed directly to the upstream ALB module security group. Defaults allow HTTP (80) and HTTPS (443) from anywhere."
  type        = any
  default = {
    http = {
      ip_protocol = "tcp"
      from_port   = 80
      to_port     = 80
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow inbound HTTP"
    }
    https = {
      ip_protocol = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow inbound HTTPS"
    }
  }
}

variable "security_group_egress_rules" {
  description = "Map of egress rule definitions passed directly to the upstream ALB module security group. Default allows all outbound traffic."
  type        = any
  default = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }
}

################################################################################
# Listeners
################################################################################

variable "listeners" {
  description = <<-EOT
    Map of listener configurations passed directly to the oceansoft/alb/aws module.
    Using type = any to avoid duplicating the upstream module's complex nested type definition.

    Example with HTTP-to-HTTPS redirect and a TLS 1.3 HTTPS listener:
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
          certificate_arn = "arn:aws:acm:..."
          forward = {
            target_group_key = "app"
          }
        }
      }
  EOT
  type        = any
  default     = {}
}

################################################################################
# Target groups
################################################################################

variable "target_groups" {
  description = <<-EOT
    Map of target group configurations passed directly to the oceansoft/alb/aws module.
    Using type = any to avoid duplicating the upstream module's complex nested type definition.

    Example:
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
  EOT
  type        = any
  default     = {}
}

################################################################################
# WAF
################################################################################

variable "associate_web_acl" {
  description = "If true, associate a WAF Web ACL (web_acl_arn) with this ALB."
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with the ALB. Only used when associate_web_acl = true."
  type        = string
  default     = null
}

################################################################################
# CloudFront
################################################################################

variable "create_cloudfront" {
  description = "If true, create a CloudFront distribution in front of the ALB."
  type        = bool
  default     = false
}

variable "cloudfront_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 for the CloudFront distribution. Required when create_cloudfront = true."
  type        = string
  default     = null
}

variable "cloudfront_aliases" {
  description = "List of domain aliases for the CloudFront distribution (e.g., ['app.example.com'])."
  type        = list(string)
  default     = []
}

variable "cloudfront_price_class" {
  description = "CloudFront price class. Valid values: PriceClass_100, PriceClass_200, PriceClass_All."
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_wait_for_deployment" {
  description = "If true, wait for the CloudFront distribution to be fully deployed."
  type        = bool
  default     = false
}

################################################################################
# WAF (managed)
################################################################################

variable "create_waf" {
  description = "If true, create a WAFv2 Web ACL with AWS Managed Rules (REGIONAL scope) and associate it with the ALB."
  type        = bool
  default     = false
}

variable "create_waf_cloudfront" {
  description = "If true, create a WAFv2 Web ACL (CLOUDFRONT scope, us-east-1) and associate it with the CloudFront distribution. Requires aws.us_east_1 provider alias."
  type        = bool
  default     = false
}

variable "websocket_paths" {
  description = "List of path patterns for WebSocket endpoints that should bypass CloudFront caching (e.g., ['/ws/*', '/socket.io/*'])."
  type        = list(string)
  default     = []
}

################################################################################
# DNS
################################################################################

variable "create_dns" {
  description = "If true, create Route53 A record alias pointing to CloudFront (if enabled) or ALB."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Fully qualified domain name for the Route53 record (e.g., 'app.example.com'). Required when create_dns = true."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS record creation. Required when create_dns = true."
  type        = string
  default     = null
}
