# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.
# Dual-region: ap-southeast-2 (default) + us-east-1 (CloudFront WAFv2 + ACM).
# Required by modules/web: configuration_aliases = [aws.us_east_1]

terraform {
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28, < 7.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = local.default_tags }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags { tags = local.default_tags }
}
