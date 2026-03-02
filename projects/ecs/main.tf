# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Minimal Fargate cluster + 1 service — sandbox consumer project
# Registry: oceansoft/ecs/aws

# Source options (select ONE):
# 1. Local path (monorepo dev):
#    source = "../../modules/ecs"
# 2. GitHub release:
#    source = "github.com/nnthanh101/terraform-aws//modules/ecs?ref=ecs/v1.0.0"
# 3. Terraform Registry (after registry-publish):
#    source  = "oceansoft/ecs/aws"
#    version = "~> 1.0"

module "ecs" {
  source = "../../modules/ecs"

  cluster_name               = "sandbox-ecs"
  cluster_capacity_providers = ["FARGATE"]

  default_tags = var.default_tags

  services = {
    api = {
      cpu         = 256
      memory      = 512
      launch_type = "FARGATE"
      subnet_ids  = var.subnet_ids
      vpc_id      = var.vpc_id

      container_definitions = {
        app = {
          image                  = "public.ecr.aws/amazonlinux/amazonlinux:2023-minimal"
          essential              = true
          cpu                    = 256
          memory                 = 512
          command                = ["sh", "-c", "echo hello && sleep 3600"]
          readonlyRootFilesystem = false
        }
      }

      security_group_egress_rules = {
        all = {
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }
    }
  }
}
