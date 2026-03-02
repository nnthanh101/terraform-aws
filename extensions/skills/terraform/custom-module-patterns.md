---
name: custom-module-patterns
description: DO/DON'T patterns for custom Terraform module development (Option C, ADR-008)
agent: [infrastructure-engineer, cloud-architect]
context: fork
model: sonnet
allowed-tools: [Read, Grep, Glob]
license: Apache-2.0
metadata:
  version: "1.0.0"
  adlc_version: "1.2.0"
visibility: public
track: public
disclosure-level: full
---

# Custom Module Patterns (Option C)

## Decision Matrix: Wrapper vs Custom

| Factor | Use Wrapper | Use Custom |
|--------|------------|------------|
| Outputs needed? | No | Yes — custom |
| Composition required? | No | Yes — custom |
| ABAC/JIT/SCIM? | No | Yes — custom |
| LOC budget? | <50 | <500 (lean core) |
| Registry publish? | Low bar | Full credibility |

## DO

| Pattern | Example |
|---------|---------|
| Direct resources | `resource "aws_ssoadmin_permission_set" "pset" {}` |
| Typed variables | `type = map(object({ ... }))` with validation |
| Real outputs | `value = { for k, v in aws_resource.x : k => v.arn }` |
| YAML + HCL dual input | `yamldecode(file(...))` with HCL override |
| Mock provider tests | `mock_provider "aws" {}` + `override_data {}` |
| Flattened for_each | `flatten()` → map with composite key |
| Copyright headers | `# Copyright 2026 nnthanh101@gmail.com (oceansoft.io)` |

## DON'T

| Anti-Pattern | Why | Fix |
|-------------|-----|-----|
| `module "x" { source = "..." }` wrapper | Zero outputs, no composition | Direct resources |
| `output "x" { value = {} }` | Useless, blocks downstream | Real resource references |
| `type = any` for all vars | No validation, hard to debug | Typed objects |
| Backend block in module | Terraform anti-pattern | Configure in examples/ only |
| `override_module` in tests | Bypasses all validation | Use `override_data` for data sources |
| `count` for for_each resources | Index-based, fragile | `for_each` with map keys |
| Hardcoded ARNs | Region/account specific | Data sources or variables |

## Resource Naming

| Convention | Example |
|-----------|---------|
| Resource type prefix | `aws_ssoadmin_permission_set.pset` |
| Plural for for_each | `aws_identitystore_group.sso_groups` |
| Singular for count | `aws_s3_bucket.audit_archive` |
| Composite key | `"${pset_name}.${policy_arn}"` |

## Testing Strategy

| Tier | Tool | Cost | Coverage |
|------|------|------|----------|
| Tier 1 | `.tftest.hcl` + `mock_provider` | $0 | Plan validation, output structure |
| Tier 2 | LocalStack + Go Terratest | $0 | Resource creation, state |
| Tier 3 | Real AWS + Go Terratest | $$ | Full integration, HITL gate |

## Quick Actions

```bash
# Validate module
terraform -chdir=modules/<name> fmt -check && terraform -chdir=modules/<name> validate

# Run Tier 1 tests
terraform -chdir=tests/snapshot init -backend=false && terraform -chdir=tests/snapshot test -verbose

# Check legal compliance
task govern:legal

# LOC budget check
wc -l modules/<name>/*.tf
```

## Verification

```bash
# Confirm real outputs (not empty)
terraform -chdir=tests/snapshot test -verbose 2>&1 | grep -c "pass"
# Expected: >= 6 test cases passing
```
