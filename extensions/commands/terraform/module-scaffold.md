---
name: module-scaffold
description: Scaffold a new Terraform module following Option C custom module patterns (ADR-008)
agent: [infrastructure-engineer, cloud-architect]
context: user
model: sonnet
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
license: Apache-2.0
metadata:
  version: "1.0.0"
  adlc_version: "1.2.0"
visibility: public
track: public
disclosure-level: full
---

# /terraform:module-scaffold

Scaffold a new Terraform module following the Option C custom module pattern.

## Usage

```
/terraform:module-scaffold <module-name>
```

## What It Creates

```
modules/<module-name>/
  main.tf          # Direct AWS resources (no wrappers)
  variables.tf     # Typed variables with validation
  outputs.tf       # Real outputs (ARNs, IDs)
  locals.tf        # Data transformations
  data.tf          # Read-only data sources
  versions.tf      # Provider constraints (>= 5.95, < 7.0)
  configs/         # YAML config files (APRA CPS 234 audit trail)
  README.md        # terraform-docs auto-generated

tests/snapshot/<module-name>_test.tftest.hcl
  # Tier 1 mock_provider tests
```

## Checklist

- [ ] Copyright header on all .tf files: `# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0. See LICENSE.`
- [ ] versions.tf: `required_version = ">= 1.10.0"`, aws `>= 5.95, < 7.0`
- [ ] NO backend block in module (anti-pattern)
- [ ] Real outputs (not empty maps)
- [ ] Variables have validation blocks where applicable
- [ ] YAML config API retained for audit-friendly inputs
- [ ] At least 6 Tier 1 test cases with `mock_provider`

## Quick Action

```bash
# After scaffolding, validate:
terraform -chdir=modules/<module-name> fmt -check -recursive
terraform -chdir=modules/<module-name> init -backend=false
terraform -chdir=modules/<module-name> validate
terraform -chdir=tests/snapshot init -backend=false && terraform -chdir=tests/snapshot test -verbose
```
