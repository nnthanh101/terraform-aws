# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

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
  region = "ap-southeast-2"

  default_tags {
    tags = {
      Project     = "terraform-aws"
      Environment = "sandbox"
      CostCenter  = "platform"
      Compliance  = "APRA-CPS234"
      ManagedBy   = "terraform"
    }
  }
}
