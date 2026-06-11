# AWS Foundation Terraform Module

Generic, reusable Terraform module for core AWS workload infrastructure.

## Usage

```hcl
module "foundation" {
  source = "../modules/foundation"

  environment            = "dev"
  name_prefix            = "myapp"
  secret_recovery_window = 7
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
| environment | Deployment environment | `string` | n/a | yes |
| name_prefix | Prefix for resource naming | `string` | `"app"` | no |
| secret_recovery_window | Recovery window in days for Secrets Manager on destroy. 0 = instant. | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| media_bucket_id | ID of the media S3 bucket |
| media_bucket_arn | ARN of the media S3 bucket |
| sqs_queue_url | URL of the application event bus SQS queue |
| sqs_queue_arn | ARN of the application event bus SQS queue |
| sqs_dlq_arn | ARN of the event bus dead-letter queue |
| sns_topic_arn | ARN of the application event bus SNS topic |
| secret_arns | Map of secret name to ARN for all Secrets Manager secrets |
