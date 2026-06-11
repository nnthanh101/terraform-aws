# GitHub Actions OIDC Terraform Module

> Original work by nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0.

## Features

- GitHub Actions OIDC provider (`token.actions.githubusercontent.com`) — one per AWS account
- **Split-trust IAM roles** (the security boundary):
  - **Plan/readonly role** — trusted from any ref (`repo:<org>/<repo>:*`); defaults to `ReadOnlyAccess`
  - **Apply role** — trusted from `main` branch ONLY (`repo:<org>/<repo>:ref:refs/heads/main`); caller-supplied least-privilege policies (no default admin)
- `create_oidc_provider = false` to reuse an existing provider (one-per-account constraint)
- Tag passthrough for cost attribution

## Basic Usage

```hcl
module "github_oidc" {
  source = "github.com/nnthanh101/terraform-aws//modules/github-oidc?ref=v0.1.0"

  github_org          = "1xOps"
  github_repositories = ["b2b-commerce"]

  # Apply role must have explicit least-privilege policies — no default.
  apply_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",  # example — scope to your needs
  ]

  tags = {
    Environment = "production"
    CostCenter  = "platform"
  }
}
```

## Contributing

See the [`CONTRIBUTING.md`](../../CONTRIBUTING.md) file for information on how to contribute.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.28, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.apply](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.apply_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.plan_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apply_policy_arns"></a> [apply\_policy\_arns](#input\_apply\_policy\_arns) | List of managed policy ARNs to attach to the apply role. REQUIRED — no default (caller must supply explicit least-privilege policy ARNs; AdministratorAccess is never assumed). | `list(string)` | n/a | yes |
| <a name="input_apply_allowed_refs"></a> [apply\_allowed\_refs](#input\_apply\_allowed\_refs) | GitHub sub-claim ref suffixes trusted by the apply role. Defaults to main-branch push. GitHub environment: claims (e.g. `environment:production`) are valid values and preferred for protected deployments requiring environment-protection reviewers. | `list(string)` | `["ref:refs/heads/main"]` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organisation name (e.g. 'nnthanh101' or '1xOps'). Used in the IAM trust-policy sub claim. | `string` | n/a | yes |
| <a name="input_github_repositories"></a> [github\_repositories](#input\_github\_repositories) | List of repository names (without org prefix) that are granted trust. Each entry becomes sub claim 'repo:<org>/<repo>:*' for the plan role and 'repo:<org>/<repo>:ref:refs/heads/main' for the apply role. | `list(string)` | n/a | yes |
| <a name="input_apply_role_name"></a> [apply\_role\_name](#input\_apply\_role\_name) | Name of the IAM role assumed by apply jobs (main-branch-only trust). | `string` | `"github-actions-apply"` | no |
| <a name="input_create_oidc_provider"></a> [create\_oidc\_provider](#input\_create\_oidc\_provider) | Whether to create the aws_iam_openid_connect_provider for token.actions.githubusercontent.com. Set to false when one already exists in the account (one-per-account constraint). | `bool` | `true` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds for both roles. | `number` | `3600` | no |
| <a name="input_plan_policy_arns"></a> [plan\_policy\_arns](#input\_plan\_policy\_arns) | List of managed policy ARNs to attach to the plan/readonly role. Defaults to ReadOnlyAccess — least-privilege for plan jobs. | `list(string)` | `["arn:aws:iam::aws:policy/ReadOnlyAccess"]` | no |
| <a name="input_plan_role_name"></a> [plan\_role\_name](#input\_plan\_role\_name) | Name of the IAM role assumed by plan/readonly jobs. | `string` | `"github-actions-plan"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apply_role_arn"></a> [apply\_role\_arn](#output\_apply\_role\_arn) | ARN of the apply IAM role (trusted from main branch only). |
| <a name="output_apply_role_name"></a> [apply\_role\_name](#output\_apply\_role\_name) | Name of the apply IAM role. |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the GitHub Actions OIDC provider. |
| <a name="output_plan_role_arn"></a> [plan\_role\_arn](#output\_plan\_role\_arn) | ARN of the plan/readonly IAM role (trusted from any ref). |
| <a name="output_plan_role_name"></a> [plan\_role\_name](#output\_plan\_role\_name) | Name of the plan/readonly IAM role. |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [nnthanh101](https://github.com/nnthanh101) (oceansoft.io).

## License

Apache 2 Licensed. See [LICENSE](../../LICENSE) for full details.
