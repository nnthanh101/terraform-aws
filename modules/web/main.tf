# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Wrapper around oceansoft/alb/aws v1.0.0 (Apache-2.0). See NOTICE.
# Value-add: ADLC governance, FOCUS 1.2+ tags, TLS 1.3 enforcement, CPS 234 compliance defaults.

module "alb" {
  source = "../alb"

  create = var.create

  name               = var.name
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.subnet_ids
  internal           = var.internal

  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = true

  # Security group — managed by upstream module
  create_security_group        = true
  security_group_ingress_rules = var.security_group_ingress_rules
  security_group_egress_rules  = var.security_group_egress_rules

  # Listeners — pass through from variable
  listeners = var.listeners

  # Target groups — pass through from variable
  target_groups = var.target_groups

  # WAF association (optional)
  associate_web_acl = var.associate_web_acl
  web_acl_arn       = var.web_acl_arn

  tags = merge(local.common_tags, var.tags)
}
