# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Derived from terraform-aws-modules/terraform-aws-alb. See NOTICE.txt.

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
      "app.terraform.io/oceansoft/alb/aws"
    ]
  }
}
