# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# GitHub Actions OIDC provider + split-trust IAM roles for keyless CI.

terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28, < 7.0"
    }
  }

  provider_meta "aws" {
    user_agent = [
      "app.terraform.io/oceansoft/github-oidc/aws"
    ]
  }
}
