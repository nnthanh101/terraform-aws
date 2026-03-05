# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from aws-ia/terraform-aws-iam-identity-center v1.0.4 (Apache-2.0). See NOTICE.

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28, < 7.0"
    }
  }
}
