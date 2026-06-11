# AWS Tags Terraform Module

Generic, reusable Terraform module for FOCUS 1.2+ compliant AWS tag composition.

## Usage

```hcl
module "tags" {
  source = "../modules/tags"

  environment      = "dev"
  application      = "my-platform"
  service          = "backend"
  owner            = "platform-team@example.com"
  cost_center      = "CC-PLATFORM-001"
  compliance       = "n/a"
  data_classification = "internal"
}

provider "aws" {
  default_tags {
    tags = module.tags.common_tags
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0, < 2.0.0 |
| null | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Deployment environment | `string` | n/a | yes |
| application | Application name for FOCUS ServiceName rollup | `string` | `"my-application"` | no |
| service | Component enum (backend/storefront/data/edge/async) | `string` | `"backend"` | no |
| owner | Owning team email or slug | `string` | `"team@example.com"` | no |
| cost_center | Finance cost center code (CC-XXXXX pattern) | `string` | `"CC-PLATFORM-001"` | no |
| compliance | Applicable compliance framework | `string` | `"n/a"` | no |
| data_classification | Data sensitivity tier | `string` | `"internal"` | no |

## Outputs

| Name | Description |
|------|-------------|
| common_tags | FOCUS 1.2+ compliant tag map (8 tags). Inject via provider `default_tags`. |
