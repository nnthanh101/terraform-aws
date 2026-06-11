# AWS AppRegistry Terraform Module

Generic, reusable Terraform module for AWS Service Catalog AppRegistry application registration.

## Usage

```hcl
module "appregistry" {
  source = "../modules/appregistry"

  enable_appregistry = true
  application_name   = "my-platform"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.0, < 2.0.0 |
| aws | >= 6.28, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| enable_appregistry | Enable AWS AppRegistry resource. Set false for LocalStack. | `bool` | `false` | no |
| application_name | AWS AppRegistry application name. | `string` | `"my-application"` | no |

## Outputs

| Name | Description |
|------|-------------|
| application_tag | AppRegistry `awsApplication` tag map. Empty when `enable_appregistry = false`. |
