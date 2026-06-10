# Migration Register — Legacy Module Backlog

## Denominator Statement

**20 of 25 entries** in `devops-docs/terraform-aws/modules/` are in scope.

Exclusions (5):

| Excluded entry | Reason |
|----------------|--------|
| `README.md` | Documentation file, not a module |
| `identity_center_assignments` | Superseded by canonical `modules/sso` v1.2.1 |
| `identity_center_aws_managed_policies` | Superseded by canonical `modules/sso` v1.2.1 |
| `identity_center_customer_managed_policies` | Superseded by canonical `modules/sso` v1.2.1 |
| `identity_center_permissions_boundary` | Superseded by canonical `modules/sso` v1.2.1 |

**Measurement method**: `ls -1 /Volumes/Working/projects/b2b-commerce/devops-docs/terraform-aws/modules/` → 25 entries; minus 4 `identity_center_*` directories + 1 `README.md` = **20 modules**. Command run 2026-06-10.

**Denominator for Wave planning**: 20 legacy + 2 new-build additions (ECR, ElastiCache) = 22 total migration tasks.

---

## Register Table

> Provider staleness legend: `~> 4.0` = AWS provider v4 (canonical requires `>= 6.28, < 7.0`); `>= 3.x` = AWS provider v3; `>= 0.12.x` = TF core only constrained.
> Effort: S = <1 day, M = 1-2 days, L = 3+ days.

| # | Module (legacy path) | Classification | Target module | Key resources | Staleness notes | Overlap w/ canonical | Effort | Wave |
|---|----------------------|----------------|---------------|---------------|-----------------|----------------------|--------|------|
| 1 | `terraform_aws_acm_certificate` | MIGRATE-W1 | `modules/acm` (exists) | `aws_acm_certificate`, `aws_route53_record`, `aws_acm_certificate_validation` | Provider `~> 4.0`; cross-provider alias (`aws.route53`) needs modernising to provider v6 alias block | `modules/acm` covers same DNS-validated cert + Route 53 record pattern | S | W1 |
| 2 | `terraform_aws_rds` | MIGRATE-W1 | `modules/rds` (NEW BUILD) | `aws_db_instance`, `aws_db_proxy`, `aws_db_subnet_group`, `aws_security_group` (×4), `aws_kms_key`, `aws_secretsmanager_secret` | Provider `~> 4.0`; plaintext password in `secret_string` — must migrate to Secrets Manager reference only; `aws_db_snapshot_copy` pattern still valid in v6 | No canonical rds module; closest is `modules/kms` (key reuse) | L | W1 |
| 3 | `terraform-aws-security-group` | MIGRATE-W1 | `modules/sg` (NEW BUILD) | `aws_security_group`, `aws_security_group_rule` | Community module pinned `>= 2.42` (AWS provider v2); TF core `>= 0.12.6`; uses legacy `aws_security_group_rule` separate resource pattern (deprecated in favour of inline rules in v5+) | No canonical sg module | M | W1 |
| 4 | `terraform-aws-vpc` | SUPERSEDED | `modules/vpc` | `aws_vpc`, `aws_subnet`, `aws_nat_gateway`, `aws_internet_gateway`, `aws_route_table`, vpc-flow-logs | Community module pinned `>= 3.38`; canonical `modules/vpc` uses provider `>= 6.28` with identical resource set and flow-log support | Canonical `modules/vpc` covers all resource types; this legacy module is the upstream source | — | — |
| 5 | `terraform_aws_waf` | SUPERSEDED | `modules/waf` | `aws_wafv2_web_acl`, `aws_wafv2_ip_set` | Provider `~> 4.0`; Akamai IP set hardcoded — canonical `modules/waf` externalises IP sets via variable | Canonical `modules/waf` covers same WAFv2 ACL + IP set pattern with `context.tf` enrichment | — | — |
| 6 | `terraform-aws-s3-bucket` | SUPERSEDED | `modules/s3` | `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_bucket_policy` | Community module pinned `>= 3.38`; uses legacy `acl` argument (removed in provider v5); canonical `modules/s3` uses `aws_s3_bucket_ownership_controls` | Canonical `modules/s3` supersedes this; check `acl` usage at call sites | — | — |
| 7 | `terraform_aws_lambda` | MIGRATE-W2 | `modules/lambda` (NEW BUILD) | `aws_lambda_function`, `aws_lambda_alias`, `aws_iam_role`, `aws_cloudwatch_log_group` | Provider `~> 4.0`; `snap_start` block present (Java only) — valid in v6; `function_version = "$LATEST"` on alias is an anti-pattern for production (pin to published version) | No canonical lambda module | M | W2 |
| 8 | `terraform_aws_api_gateway` | MIGRATE-W2 | `modules/api-gateway` (NEW BUILD) | `aws_api_gateway_rest_api`, `aws_api_gateway_stage`, `aws_api_gateway_deployment`, `aws_api_gateway_domain_name`, `aws_wafv2_web_acl_association`, `aws_cloudwatch_log_group` (×2) | Provider `~> 4.0`; `ignore_changes = all` on stage is a known drift-suppression smell; REST API v1 — check if HTTP API (v2) is preferred for B2B use case | No canonical api-gateway module; `modules/waf` provides the WAF ACL it associates to | M | W2 |
| 9 | `terraform_aws_cognito` | MIGRATE-W2 | `modules/cognito` (NEW BUILD) | `aws_cognito_user_pool`, `aws_cognito_user_pool_domain`, `aws_cognito_resource_server`, `aws_cognito_user_pool_client` | Provider `~> 4.0`; no MFA or password policy set — must add before production; no `advanced_security_mode` | No canonical cognito module; B2B platform uses Keycloak (SSO live per MEMORY.md) — verify Cognito is still needed | M | W2 |
| 10 | `terraform-aws-sns` | MIGRATE-W2 | `modules/sns` (NEW BUILD) | `aws_sns_topic`, `aws_sns_topic_subscription` (via wrappers) | Community module pinned `>= 3.37`; TF core `>= 0.12.26`; uses `aws_sns_topic_policy` inline — still valid in v6 | No canonical sns module | S | W2 |
| 11 | `terraform-aws-transit-gateway` | MIGRATE-W2 | `modules/tgw` (NEW BUILD) | `aws_ec2_transit_gateway`, `aws_ec2_transit_gateway_vpc_attachment`, `aws_ec2_transit_gateway_route` | Community module pinned `>= 3.15.0`; TF core `>= 0.12.26`; no breaking resource changes in v6 | No canonical tgw module; used by networking layer only | M | W2 |
| 12 | `terraform-aws-iam` | MIGRATE-W2 | `modules/iam` (NEW BUILD) | Multi-submodule: `iam-role`, `iam-policy`, `iam-user`, `iam-assumable-role*` (10 sub-modules) | Community module TF core `>= 0.12.31`; no explicit AWS provider version; largest surface area of any legacy module | No canonical iam module; `modules/sso` covers SSO-specific IAM only | L | W2 |
| 13 | `terraform_aws_codebuild` | SKIP | — | `aws_codebuild_project`, `aws_security_group`, `aws_iam_role`, `aws_cloudwatch_log_group` | Provider `~> 4.0`; CI/CD service — B2B platform uses GitHub Actions (`.github/workflows/`) not CodeBuild | Not in B2B platform roadmap; re-entry condition: explicit decision to adopt AWS CodePipeline for build |
| 14 | `terraform_aws_codepipeline_bucket` | SKIP | — | `aws_kms_key`, `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`, `aws_s3_object` | Provider `~> 4.0`; paired with CodeBuild/CodePipeline which is not used | Same re-entry condition as codebuild |
| 15 | `terraform_aws_codepipeline_iam` | SKIP | — | `aws_iam_role`, `aws_iam_role_policy` (×4 for pipeline, s3, kms, codestar) | Provider `~> 4.0`; IAM only for CodePipeline service — not needed absent CodePipeline adoption | Same re-entry condition as codebuild |
| 16 | `terraform_aws_chatbot` | SKIP | — | `aws_cloudformation_stack` (wraps `aws_chatbot_slack_channel_configuration` via CFN), `aws_iam_role` | Provider `~> 4.0`; uses CloudFormation wrapper because `aws_chatbot_*` resources were not in provider at authoring time — now natively supported in AWS provider v5+; Slack integration is ops-tooling, not B2B platform | Re-entry condition: ops team decision to add Slack ChatOps alerting |
| 17 | `terraform_aws_dms` | SKIP | — | `aws_dms_replication_instance`, `aws_dms_endpoint`, `aws_dms_replication_task`, `aws_route`, `aws_security_group` | Provider `~> 4.0`; `publicly_accessible = true` on replication instance is a security violation; cross-account TGW routing embedded — high coupling | Re-entry condition: data migration project requiring DMS; not part of steady-state B2B operations |
| 18 | `terraform_aws_elasticbeanstalk` | SKIP | — | `aws_elastic_beanstalk_application`, `aws_elastic_beanstalk_environment`, `aws_security_group` (×2), `aws_route53_record` | Provider `~> 4.0`; Elastic Beanstalk is deprecated by AWS for new workloads; B2B backend runs on ECS (canonical `modules/ecs`); `solution_stack_name` data source is tightly coupled to platform-specific AMI | Re-entry condition: none — ECS is the forward path; this module should be archived |
| 19 | `terraform-gwlbe-plus-vpc` | SKIP | — | `aws_vpc`, `aws_subnet`, `aws_nat_gateway`, `aws_internet_gateway`, plus Gateway Load Balancer Endpoint routing | Community module pinned `>= 3.38`; GWLBE pattern is network security (inline inspection) — not required for B2B MVP; canonical `modules/vpc` handles base VPC | Re-entry condition: network security team decision to deploy inline inspection (firewall appliances) |
| 20 | `terraform-gwlbe-tgw-vpc` | SKIP | — | Same as `terraform-gwlbe-plus-vpc` plus `aws_ec2_transit_gateway_vpc_attachment` | Community module pinned `>= 3.38`; variant of GWLBE pattern adding TGW attachment; same rationale as row 19 | Re-entry condition: same as row 19; evaluate consolidating rows 19–20 into a single inspection-vpc module if adopted |

---

## New-Build Additions (no legacy source)

| # | Module | Classification | Key resources | Rationale | Effort | Wave |
|---|--------|----------------|---------------|-----------|--------|------|
| N1 | `modules/ecr` (NEW BUILD) | MIGRATE-W1 | `aws_ecr_repository`, `aws_ecr_lifecycle_policy`, `aws_ecr_repository_policy` | B2B backend container images need ECR; no legacy source exists; ECS module (`modules/ecs`) consumes ECR image URI | S | W1 |
| N2 | `modules/elasticache` (NEW BUILD) | MIGRATE-W1 | `aws_elasticache_replication_group`, `aws_elasticache_subnet_group`, `aws_security_group` | Redis 7-alpine in `docker-compose.yml`; production target is ElastiCache Redis; no legacy source | M | W1 |

---

## 5W1H — Per-Classification Cohort

### MIGRATE-W1 (modules 1–3 + N1, N2): Platform-critical, Sprint 1

| Question | Answer |
|----------|--------|
| **Why** | ACM, RDS, security-group, ECR, and ElastiCache are load-bearing for the B2B production stack; ECS (already canonical) cannot serve HTTPS traffic without ACM, cannot persist data without RDS, and cannot pull images without ECR |
| **What if missing** | Production deployment blocked; `task tf:validate` passes but `terraform apply` fails at the networking/data tier |
| **Business value** | Unblocks TI-3 production-readiness sprint; enables `task tf:cost` to price the full data tier accurately |
| **Purpose** | Modernise these modules to TF `>= 1.11` + AWS provider `>= 6.28` so they can be consumed by the derived-module pattern (ADR-023) |
| **Critical thinking** | ACM already has a canonical module — migration is a wrapper write + test, not a net-new build; RDS is the highest-effort W1 item due to proxy + KMS + secret complexity |

### MIGRATE-W2 (modules 7–12): Relevant later, Sprint 2

| Question | Answer |
|----------|--------|
| **Why** | Lambda, API Gateway, Cognito, SNS, TGW, and IAM are referenced in the broader platform but not on the B2B MVP critical path |
| **What if missing** | W2 gap does not block W1 deployment; gaps surface when serverless or notification features are added |
| **Business value** | SNS enables order/quote event notifications; Lambda + API Gateway enable webhook endpoints; IAM modernisation reduces drift risk |
| **Critical thinking** | Cognito may be redundant given Keycloak SSO is live (MEMORY.md 2026-06-09); confirm before investing in a Cognito module — consider SKIP reclassification if Keycloak covers all auth flows |

### SUPERSEDED (modules 4–6): Covered by canonical

| Question | Answer |
|----------|--------|
| **Why** | Canonical `modules/vpc`, `modules/waf`, `modules/s3` were derived from or are functionally equivalent to these legacy modules |
| **What if missing** | N/A — superseded modules are already replaced; call sites must be updated to point to canonical paths |
| **Business value** | Removing legacy references eliminates dual-maintenance; `task tf:validate` surface area shrinks |
| **Critical thinking** | `terraform-aws-s3-bucket` used the now-removed `acl` argument; any call site still setting `acl` will fail against `modules/s3` — audit call sites before removing the legacy path |

### SKIP (modules 13–20): Not in B2B platform roadmap

| Question | Answer |
|----------|--------|
| **Why** | CodeBuild/CodePipeline replaced by GitHub Actions; ElasticBeanstalk superseded by ECS; DMS and Chatbot are project-specific; GWLBE is network-security-team scope |
| **What if missing** | No production impact; skipped modules should be archived in `devops-docs` with a deprecation notice pointing to the re-entry condition |
| **Business value** | Not building unused modules saves ~6-8 engineer-days in TI-3/TI-4 and avoids checkov/tflint debt on dead code |
| **Critical thinking** | DMS `publicly_accessible = true` is a security violation — if DMS is ever re-entered, this must be the first remediation item. Chatbot should be rebuilt natively using `aws_chatbot_slack_channel_configuration` (not CFN wrapper) if adopted |

---

## Migration Recipe (per module, followed by TI-3)

Each MIGRATE row follows this 7-step recipe. Steps are sequential; each has a verify gate.

```
Step 1 — SALVAGE
  Read legacy main.tf, variables.tf, outputs.tf.
  Extract all resource types, variable names, and output names into a salvage list.
  Verify: salvage list file exists at tmp/b2b-commerce/migration/<module>/salvage.md

Step 2 — MODERNISE to TF >= 1.11 + AWS provider >= 6.28, < 7.0
  Replace providers.tf with:
    terraform {
      required_version = ">= 1.11.0"
      required_providers {
        aws = { source = "hashicorp/aws", version = ">= 6.28, < 7.0" }
      }
    }
  Remove deprecated arguments (acl on S3, publicly_accessible=true on DMS proxy).
  Add aws_s3_bucket_ownership_controls where acl was used.
  Verify: terraform validate passes in container (nnthanh101/terraform:slim)

Step 3 — NOTICE + derived-module header (ADR-023)
  Add NOTICE.txt at module root citing original source and licence.
  Add header comment block in main.tf:
    # Derived from: devops-docs/terraform-aws/modules/<legacy-name>
    # Modernised: TF >= 1.11, AWS provider >= 6.28
    # ADR-023: derived-module pattern
  Verify: NOTICE.txt present, header in main.tf line 1-5

Step 4 — .tftest.hcl snapshot tests
  Create tests/<module>.tftest.hcl with at minimum:
    - one mock provider block
    - one run block asserting outputs are non-null
    - one run block asserting resource count == expected
  Verify: terraform test -filter=tests/<module>.tftest.hcl passes (zero skip, zero fail)

Step 5 — terraform-docs README
  Run: docker run --rm -v $(pwd):/workspace -w /workspace/modules/<module> \
         nnthanh101/terraform:slim \
         terraform-docs markdown table . > README.md
  Verify: README.md exists, contains ## Inputs and ## Outputs sections

Step 6 — release-please entry
  Add module to .release-please-manifest.json:
    "modules/<module-name>": "0.1.0"
  Add entry to release-please-config.json packages block.
  Verify: jq '.["modules/<module-name>"]' .release-please-manifest.json == "0.1.0"

Step 7 — checkov + tflint clean
  Run: docker run --rm -v $(pwd):/workspace -w /workspace/modules/<module> \
         nnthanh101/terraform:slim \
         sh -c "checkov --directory . --framework terraform --compact && tflint"
  Verify: zero HIGH/CRITICAL findings from checkov; zero errors from tflint
```

---

## Classification Tally

| Classification | Count | Module numbers |
|----------------|-------|----------------|
| MIGRATE-W1 | 5 | 1 (acm), 2 (rds), 3 (sg) + N1 (ecr), N2 (elasticache) |
| MIGRATE-W2 | 6 | 7 (lambda), 8 (api-gateway), 9 (cognito), 10 (sns), 11 (tgw), 12 (iam) |
| SUPERSEDED | 3 | 4 (vpc), 5 (waf), 6 (s3) |
| SKIP | 8 | 13 (codebuild), 14 (codepipeline-bucket), 15 (codepipeline-iam), 16 (chatbot), 17 (dms), 18 (elasticbeanstalk), 19 (gwlbe-plus-vpc), 20 (gwlbe-tgw-vpc) |
| **Total (legacy)** | **20** | Rows 1–20 |
| **Total (incl. new-build)** | **22** | Rows 1–20 + N1, N2 |

MIGRATE-W1 (3 legacy) + MIGRATE-W2 (6 legacy) + SUPERSEDED (3) + SKIP (8) = **20**. Denominator check passes.

---

*Generated: 2026-06-10 | scope_id: B2B-OPS-TRACKI-TI0-2026-06-10 | Measurement command: `ls -1 devops-docs/terraform-aws/modules/ | wc -l` → 25 entries*
