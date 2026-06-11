# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Example: mvp-alb-only — minimal ALB wrapper with HTTP redirect, TLS 1.3 HTTPS listener,
# a single target group, and FOCUS 1.2+ tags (ADR-005).

module "web" {
  source = "../../"

  providers = {
    aws           = aws
    aws.us_east_1 = aws
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

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
      certificate_arn = var.certificate_arn
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
      # create_attachment = false: targets are registered externally (e.g. ECS service).
      # Set to true and provide target_id when registering static IPs or EC2 instances.
      create_attachment = false
      health_check = {
        enabled             = true
        path                = "/health"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
        timeout             = 5
        matcher             = "200-399"
      }
    }
  }

  tags = {
    # FOCUS 1.2+ mandatory tags
    CostCenter  = "platform"
    Environment = "production"
    Project     = "web"
    Owner       = "platform-team"
  }
}
