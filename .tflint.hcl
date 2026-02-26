# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.

plugin "aws" {
  enabled = true
  version = "0.36.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  call_module_type    = "local"
  # Exclude upstream examples (aws-ia verbatim) from lint — Tier 3 upstream tests cover them
  ignore_module = {
    "aws-ia/iam-identity-center/aws" = true
  }
}

# Suppress required_version/providers warnings for upstream examples
rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}
