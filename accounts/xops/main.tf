# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# xOps account composition: KMS → EFS → ECS → Web (ALB+CloudFront+WAFv2+DNS).
# Derived modules (ADR-023): FOCUS 1.2+ tags, APRA CPS 234 defaults, TLS 1.3 enforcement.

locals {
  name = "${var.project_name}-${var.environment}"

  default_tags = merge(var.default_tags, {
    Environment = var.environment
    Project     = var.project_name
  })

  container_env = [
    { name = "LITELLM_MODEL", value = "anthropic/claude-sonnet-4-20250514" },
    { name = "DATABASE_URL", value = "sqlite:///workspace/data/xops.db" },
    { name = "CLOUDOPS_DOCS_PATH", value = "/workspace/data/cloudops-docs" },
    { name = "CREWAI_MAX_ITER", value = "3" },
    { name = "LITELLM_TPM_LIMIT", value = "10000" },
  ]
}

################################################################################
# 0. Standalone ECS Security Group (CA-S211-C02: breaks circular dependency)
#    EFS-SG needs ECS-SG ID, ECS needs EFS ID — standalone SG resolves this.
################################################################################

resource "aws_security_group" "ecs_service" {
  name_prefix = "${local.name}-ecs-"
  description = "Security group for xOps ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, {
    Name = "${local.name}-ecs-service"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs_service.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

################################################################################
# 1. KMS — EFS encryption key (modules/kms)
#    APRA CPS 234: CMK with auto-rotation, 7-day deletion window.
################################################################################

module "kms_efs" {
  source = "../../modules/kms"

  description             = "${local.name} EFS encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  aliases                 = ["alias/${local.name}-efs"]

  tags = local.default_tags
}

################################################################################
# 2. EFS — Persistent storage for SQLite + ChromaDB (modules/efs)
#    2 access points: xops-data (SQLite) + xops-chroma (embeddings).
#    CPS 234: encrypted at rest (KMS CMK), deny non-secure transport.
################################################################################

module "efs" {
  source = "../../modules/efs"

  name        = "${local.name}-efs"
  encrypted   = true
  kms_key_arn = module.kms_efs.key_arn

  throughput_mode  = "bursting"
  performance_mode = "generalPurpose"

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  # Mount targets — one per private subnet (multi-AZ)
  mount_targets = {
    for idx, sid in var.private_subnet_ids : "az-${idx}" => {
      subnet_id = sid
    }
  }

  # Security group — allow NFS from ECS tasks
  create_security_group = true
  security_group_vpc_id = var.vpc_id
  security_group_ingress_rules = {
    ecs = {
      description                  = "NFS from ECS tasks"
      from_port                    = 2049
      to_port                      = 2049
      ip_protocol                  = "tcp"
      referenced_security_group_id = aws_security_group.ecs_service.id
    }
  }

  # Access points — UID 1000 matches container non-root user
  access_points = {
    xops-data = {
      name       = "xops-data"
      posix_user = { uid = 1000, gid = 1000 }
      root_directory = {
        path = "/xops-data"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "0755"
        }
      }
    }
    xops-chroma = {
      name       = "xops-chroma"
      posix_user = { uid = 1000, gid = 1000 }
      root_directory = {
        path = "/xops-chroma"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "0755"
        }
      }
    }
  }

  deny_nonsecure_transport = true # CPS 234: TLS in transit
  create_backup_policy     = true

  tags = local.default_tags
}

################################################################################
# 3. ECS — Cluster + xops-api service (modules/ecs)
#    ARM64 Graviton, Fargate, EFS volumes, deployment circuit breaker.
################################################################################

module "ecs" {
  source = "../../modules/ecs"

  cluster_name               = "${local.name}-cluster"
  cluster_capacity_providers = ["FARGATE"]
  create_task_exec_iam_role  = true
  task_exec_secret_arns      = values(var.secrets_arns)
  default_tags               = local.default_tags

  services = {
    xops-api = {
      cpu    = var.cpu
      memory = var.memory

      launch_type   = "FARGATE"
      desired_count = var.desired_count
      subnet_ids    = var.private_subnet_ids
      vpc_id        = var.vpc_id

      # Use standalone SG (CA-S211-C02: circular dep resolution)
      create_security_group = false
      security_group_ids    = [aws_security_group.ecs_service.id]

      runtime_platform = {
        cpu_architecture        = "ARM64"
        operating_system_family = "LINUX"
      }

      container_definitions = {
        app = {
          image     = var.container_image
          essential = true
          cpu       = var.cpu
          memory    = var.memory

          readonly_root_filesystem = false

          port_mappings = [{
            containerPort = var.container_port
            protocol      = "tcp"
          }]

          environment = local.container_env

          secrets = [
            for k, v in var.secrets_arns : {
              name      = k
              valueFrom = v
            }
          ]

          mount_points = [
            {
              sourceVolume  = "xops-data"
              containerPath = "/workspace/data"
              readOnly      = false
            },
            {
              sourceVolume  = "xops-chroma"
              containerPath = "/workspace/.chroma"
              readOnly      = false
            },
          ]

          log_configuration = {
            log_driver = "awslogs"
            options = {
              "awslogs-group"         = "/ecs/${local.name}"
              "awslogs-region"        = var.region
              "awslogs-stream-prefix" = "xops-api"
            }
          }
        }
      }

      # EFS volumes (CA-S211-C04: use volume, not volume_configuration)
      volume = {
        xops-data = {
          efs_volume_configuration = {
            file_system_id     = module.efs.id
            transit_encryption = "ENABLED"
            authorization_config = {
              access_point_id = module.efs.access_points["xops-data"].id
              iam             = "ENABLED"
            }
          }
        }
        xops-chroma = {
          efs_volume_configuration = {
            file_system_id     = module.efs.id
            transit_encryption = "ENABLED"
            authorization_config = {
              access_point_id = module.efs.access_points["xops-chroma"].id
              iam             = "ENABLED"
            }
          }
        }
      }

      # ALB target group registration
      load_balancer = {
        app = {
          container_name   = "app"
          container_port   = var.container_port
          target_group_arn = module.web.target_group_arns["xops-api"].arn
        }
      }

      # Deployment safety
      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }
    }
  }
}

# CA-S211-C02: ALB → ECS ingress rule (added after module.web creates the SG)
resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.ecs_service.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = module.web.security_group_id
  description                  = "Allow inbound from ALB"
}

################################################################################
# 4. Web — ALB + CloudFront + WAFv2 + DNS (modules/web)
#    CA-S211-C03: providers block required for dual-scope WAFv2.
################################################################################

module "web" {
  source = "../../modules/web"

  # CA-S211-C03: Explicit provider aliases for CLOUDFRONT-scope WAFv2
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name       = local.name
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids # ALB in public subnets

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
      certificate_arn = var.alb_certificate_arn
      forward = {
        target_group_key = "xops-api"
      }
    }
  }

  target_groups = {
    xops-api = {
      protocol    = "HTTP"
      port        = var.container_port
      target_type = "ip"
      health_check = {
        enabled = true
        path    = "/health"
        matcher = "200-299"
      }
    }
  }

  # CloudFront
  create_cloudfront          = var.create_cloudfront
  cloudfront_certificate_arn = var.cloudfront_certificate_arn
  cloudfront_aliases         = var.domain_name != null ? [var.domain_name] : []
  cloudfront_price_class     = "PriceClass_200" # Includes AP region

  # WebSocket bypass — CachingDisabled for real-time paths
  websocket_paths = ["/ws/*", "/socket.io/*"]

  # WAFv2 dual-scope
  create_waf            = var.create_waf            # REGIONAL for ALB
  create_waf_cloudfront = var.create_waf_cloudfront # CLOUDFRONT (us-east-1)

  # DNS
  create_dns      = var.route53_zone_id != null
  domain_name     = var.domain_name
  route53_zone_id = var.route53_zone_id

  tags = local.default_tags
}

################################################################################
# 5. KMS Grant — ECS task execution role access to EFS encryption key
#    CA-S211-C05: Deferred grant (KMS exists before ECS, grant wires them).
################################################################################

resource "aws_kms_grant" "ecs_efs" {
  name              = "${local.name}-ecs-efs-access"
  key_id            = module.kms_efs.key_arn
  grantee_principal = module.ecs.task_exec_iam_role_arn

  operations = [
    "Decrypt",
    "DescribeKey",
    "GenerateDataKey",
  ]
}
