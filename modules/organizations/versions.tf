# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.
# Provider constraints: ADR-003 (>= 6.28, < 7.0), terraform >= 1.11.0

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28, < 7.0"
    }
  }
}
