# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Tier 1 snapshot test: Multiple services via for_each

mock_provider "aws" {}

run "multi_service_plan" {
  command = plan

  variables {
    cluster_name               = "test-multi-svc"
    cluster_capacity_providers = ["FARGATE"]
    services = {
      api = {
        create         = true
        create_service = true
        cpu            = 512
        memory         = 1024
        container_definitions = {
          api = {
            cpu       = 256
            memory    = 512
            essential = true
            image     = "public.ecr.aws/nginx/nginx:latest"
            port_mappings = [{
              name          = "http"
              containerPort = 80
              hostPort      = 80
              protocol      = "tcp"
            }]
          }
        }
        create_task_exec_iam_role = false
        create_tasks_iam_role     = false
        task_definition_arn       = "arn:aws:ecs:us-east-1:123456789012:task-definition/mock:1"
        subnet_ids                = ["subnet-abc123"]
      }
      worker = {
        create         = true
        create_service = true
        cpu            = 256
        memory         = 512
        container_definitions = {
          worker = {
            cpu       = 256
            memory    = 512
            essential = true
            image     = "public.ecr.aws/nginx/nginx:latest"
          }
        }
        create_task_exec_iam_role = false
        create_tasks_iam_role     = false
        task_definition_arn       = "arn:aws:ecs:us-east-1:123456789012:task-definition/mock:1"
        subnet_ids                = ["subnet-abc123"]
      }
    }
    tags = {
      Environment = "test"
      Project     = "ecs"
    }
  }

  # Assert: 2 services planned
  assert {
    condition     = length(module.service) == 2
    error_message = "Expected 2 services (api, worker) to be planned"
  }
}
