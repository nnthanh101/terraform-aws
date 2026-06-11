# Copyright 2026 nnthanh101@gmail.com. Licensed under Apache-2.0. See LICENSE.
# Provider constraints: ADR-003 (terraform >= 1.10.0, < 2.0.0); null ~> 3.0

terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
