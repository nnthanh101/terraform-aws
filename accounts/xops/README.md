# xOps Account Composition

> **Sprint**: xOps-S2 | **Story**: S2-11 | **Cost Target**: BC1 ≤$100/mo | **Region**: ap-southeast-2

Composes 4 derived modules from `terraform-aws/modules/` into a complete xOps deployment stack.
All modules follow ADR-023 (derived module pattern) with FOCUS 1.2+ tags, APRA CPS 234 defaults, and TLS 1.3 enforcement.

## D1 — Module Dependency Graph

The standalone `aws_security_group.ecs_service` at the top breaks the circular dependency
between EFS (needs ECS SG ID for NFS ingress) and ECS (needs EFS filesystem ID for volume mounts).

```mermaid
graph TD
    SG["<b>aws_security_group.ecs_service</b><br/>Standalone SG — no deps<br/><i>CA-S211-C02</i>"]
    KMS["<b>module.kms_efs</b><br/>modules/kms<br/>CMK auto-rotation, 7-day deletion<br/>~$1/mo"]
    EFS["<b>module.efs</b><br/>modules/efs<br/>Encrypted, 2 access points<br/>deny_nonsecure_transport=true<br/>~$3/mo"]
    ECS["<b>module.ecs</b><br/>modules/ecs<br/>Fargate ARM64 1vCPU/2GB<br/>Circuit breaker + rollback<br/>~$30/mo"]
    WEB["<b>module.web</b><br/>modules/web<br/>ALB + CloudFront + WAFv2 dual-scope<br/>TLS 1.3 + WebSocket bypass<br/>~$38-52/mo"]
    GRANT["<b>aws_kms_grant.ecs_efs</b><br/>Decrypt + DescribeKey + GenerateDataKey<br/><i>CA-S211-C05</i>"]
    INGRESS["<b>aws_vpc_security_group_ingress_rule</b><br/>ALB → ECS port 8080"]

    SG -->|"SG ID (NFS ingress)"| EFS
    SG -->|"SG ID (security_group_ids)"| ECS
    KMS -->|"key_arn"| EFS
    EFS -->|"id + access_points"| ECS
    ECS -->|"target_group_arns[xops-api]"| WEB
    KMS -->|"key_arn"| GRANT
    ECS -->|"task_exec_iam_role_arn"| GRANT
    WEB -->|"security_group_id"| INGRESS
    SG -->|"id"| INGRESS

    style SG fill:#e1f5fe,stroke:#0277bd
    style KMS fill:#fff3e0,stroke:#e65100
    style EFS fill:#e8f5e9,stroke:#2e7d32
    style ECS fill:#f3e5f5,stroke:#6a1b9a
    style WEB fill:#fce4ec,stroke:#c62828
    style GRANT fill:#fff3e0,stroke:#e65100
    style INGRESS fill:#e1f5fe,stroke:#0277bd
```

**Dependency resolution order** (Terraform resolves automatically):

```
1. aws_security_group.ecs_service  (no dependencies)
2. module.kms_efs                  (no dependencies — parallel with #1)
3. module.efs                      (depends on #1 SG ID + #2 key_arn)
4. module.web                      (no module deps — ALB created independently)
5. module.ecs                      (depends on #3 EFS ID + #4 target_group_arn)
6. aws_kms_grant.ecs_efs           (depends on #2 key_arn + #5 task_exec_role_arn)
7. aws_vpc_security_group_ingress  (depends on #1 SG ID + #4 web SG ID)
```

## D2 — Network Topology

```mermaid
graph LR
    USER["👤 User / HITL"]

    subgraph "us-east-1"
        WAF_CF["WAFv2<br/>CLOUDFRONT scope<br/>AWS Managed Rules"]
        ACM_CF["ACM Certificate<br/>TLSv1.2_2025 minimum"]
    end

    subgraph "ap-southeast-2"
        CF["CloudFront<br/>PriceClass_200<br/>WebSocket bypass: /ws/* /socket.io/*"]

        subgraph "VPC"
            subgraph "Public Subnets (≥2 AZs)"
                ALB["ALB<br/>TLS 1.3 (ELBSecurityPolicy-TLS13-1-2-2021-06)<br/>HTTP→HTTPS redirect"]
                WAF_ALB["WAFv2<br/>REGIONAL scope"]
            end

            subgraph "Private Subnets (≥2 AZs)"
                ECS["ECS Fargate<br/>ARM64 1vCPU/2GB<br/>xops-api:8080<br/>Non-root UID 1000"]
                EFS["EFS<br/>Encrypted (KMS CMK)<br/>Bursting throughput"]
                EFS_AP1["AP: xops-data<br/>/workspace/data<br/>SQLite WAL"]
                EFS_AP2["AP: xops-chroma<br/>/workspace/.chroma<br/>ChromaDB embeddings"]
            end
        end

        SM["Secrets Manager<br/>ANTHROPIC_API_KEY"]
        ECR["ECR<br/>xops-api image"]
        CW["CloudWatch Logs<br/>/ecs/xops-dev<br/>90-day retention"]
        KMS["KMS CMK<br/>Auto-rotation<br/>7-day deletion"]
    end

    USER -->|"HTTPS"| CF
    CF -->|"Origin: HTTPS-only"| ALB
    WAF_CF -.->|"Protects"| CF
    ACM_CF -.->|"TLS cert"| CF
    WAF_ALB -.->|"Protects"| ALB
    ALB -->|"HTTP :8080"| ECS
    ECS -->|"NFS :2049 (TLS)"| EFS
    EFS --- EFS_AP1
    EFS --- EFS_AP2
    ECS -.->|"Pull image"| ECR
    ECS -.->|"Inject secrets"| SM
    ECS -.->|"Logs"| CW
    KMS -.->|"Encrypts"| EFS

    style USER fill:#f5f5f5,stroke:#424242
    style CF fill:#fce4ec,stroke:#c62828
    style ALB fill:#fce4ec,stroke:#c62828
    style ECS fill:#f3e5f5,stroke:#6a1b9a
    style EFS fill:#e8f5e9,stroke:#2e7d32
    style KMS fill:#fff3e0,stroke:#e65100
```

## D3 — Security Controls (APRA CPS 234)

```mermaid
graph TD
    subgraph "Edge Protection"
        W1["WAFv2 CLOUDFRONT<br/>us-east-1<br/>AWSManagedRulesCommonRuleSet<br/>AWSManagedRulesKnownBadInputsRuleSet"]
        W2["WAFv2 REGIONAL<br/>ap-southeast-2<br/>AWSManagedRulesCommonRuleSet<br/>Rate limiting"]
    end

    subgraph "Transport Security"
        T1["CloudFront → ALB<br/>origin_protocol_policy: https-only<br/>origin_ssl_protocols: TLSv1.2"]
        T2["ALB Listener<br/>ssl_policy: ELBSecurityPolicy-TLS13-1-2-2021-06<br/>HTTP 80 → HTTPS 301 redirect"]
        T3["EFS Transit Encryption<br/>transit_encryption: ENABLED<br/>deny_nonsecure_transport: true"]
    end

    subgraph "Data at Rest"
        D1["EFS Encryption<br/>encrypted: true<br/>KMS CMK (not AWS-managed)"]
        D2["KMS Key Management<br/>enable_key_rotation: true<br/>deletion_window: 7 days"]
        D3["KMS Grant<br/>Least-privilege: Decrypt,<br/>DescribeKey, GenerateDataKey"]
    end

    subgraph "Network Isolation"
        N1["ALB: Public subnets only<br/>SG: 80/443 from 0.0.0.0/0"]
        N2["ECS: Private subnets only<br/>SG: 8080 from ALB SG only"]
        N3["EFS: Private subnets only<br/>SG: 2049 from ECS SG only"]
    end

    subgraph "Container Hardening"
        C1["Non-root UID 1000<br/>POSIX user enforcement<br/>via EFS access points"]
        C2["Secrets Manager injection<br/>No env var literals for API keys"]
        C3["Deployment circuit breaker<br/>Auto-rollback on failure"]
    end

    subgraph "Backup & Recovery"
        B1["EFS backup policy: ENABLED<br/>AWS Backup automatic"]
        B2["EFS lifecycle: IA after 30 days<br/>Primary on first access"]
    end

    style W1 fill:#ffcdd2,stroke:#b71c1c
    style W2 fill:#ffcdd2,stroke:#b71c1c
    style T1 fill:#bbdefb,stroke:#0d47a1
    style T2 fill:#bbdefb,stroke:#0d47a1
    style T3 fill:#bbdefb,stroke:#0d47a1
    style D1 fill:#fff9c4,stroke:#f57f17
    style D2 fill:#fff9c4,stroke:#f57f17
    style D3 fill:#fff9c4,stroke:#f57f17
    style N1 fill:#c8e6c9,stroke:#1b5e20
    style N2 fill:#c8e6c9,stroke:#1b5e20
    style N3 fill:#c8e6c9,stroke:#1b5e20
    style C1 fill:#e1bee7,stroke:#4a148c
    style C2 fill:#e1bee7,stroke:#4a148c
    style C3 fill:#e1bee7,stroke:#4a148c
```

## D4 — Cost Breakdown (BC1 Target: ≤$100/mo)

| Component | Module | Spec | Monthly Cost |
|-----------|--------|------|-------------|
| ECS Fargate | `modules/ecs` | ARM64 Graviton, 1 vCPU, 2 GB, 1 task | $30 |
| ALB | `modules/web` → `modules/alb` | 1 LB, HTTPS listener, health checks | $25 |
| CloudFront | `modules/web` → `modules/cloudfront` | PriceClass_200 (includes AP), WebSocket bypass | $7–15 |
| WAFv2 (dual) | `modules/web` | REGIONAL + CLOUDFRONT scope, 2 managed rule groups | $6–12 |
| EFS | `modules/efs` | Bursting throughput, ~5 GB (SQLite + ChromaDB) | $3 |
| KMS CMK | `modules/kms` | 1 key, auto-rotation enabled | $1 |
| ECR | _(inline)_ | ~2 GB image storage | $2 |
| CloudWatch | _(inline)_ | `/ecs/xops-dev`, 90-day retention | $3–5 |
| Secrets Manager | _(inline)_ | 1 secret (ANTHROPIC_API_KEY) | $1 |
| ACM | _(free)_ | 2 certificates (ap-southeast-2 + us-east-1) | $0 |
| Route53 | `modules/web` | 1 hosted zone + 1 alias record | $0.50 |
| **Total** | | **BC1 ECS deployment** | **$78–94/mo** |

### Cost by Phase

| Phase | What | Monthly Cost |
|-------|------|-------------|
| **BC1 Local** | Docker Compose (Ollama + WebUI + API) | $0 |
| **BC1 ECS** | ECS Fargate + ALB + CF + WAF + EFS (no Ollama) | $78–94 |
| **BC2** | BC1 ECS + Ollama 8B on separate ECS task (2vCPU/8GB) | $150–180 |

### ROI

| Metric | Value |
|--------|-------|
| Current SaaS cost | $2,000/mo |
| BC1 ECS target | ≤$100/mo |
| Savings | $1,900+/mo (95%) |
| ROI multiplier | **21× at BC1** |

## Source Strategy (ADR-026)

| Context | Module Source |
|---------|-------------|
| **Dev** (local iteration) | `source = "../../modules/{name}"` |
| **Prod** (versioned) | `source = "github.com/nnthanh101/terraform-aws//modules/{name}?ref=v2.2.1"` |
| **Registry** (backup) | `source = "app.terraform.io/oceansoft/{name}/aws"` |

## Quick Start

```bash
# 1. Init (portable — bucket injected at init time)
cd accounts/xops
terraform init \
  -backend-config="bucket=${ACCOUNT_ID}-tfstate-ap-southeast-2" \
  -backend-config="region=ap-southeast-2"

# 2. Validate (no credentials needed)
terraform validate
terraform fmt -check

# 3. Plan (requires AWS credentials)
terraform plan -var-file=dev.tfvars -out=tfplan

# 4. Cost estimate
infracost diff --path=. --terraform-var-file=dev.tfvars

# 5. Security scan
checkov -d . --framework terraform

# 6. Apply (HITL gate — requires explicit approval)
terraform apply tfplan
```

## Files

| File | LOC | Purpose |
|------|-----|---------|
| `providers.tf` | 23 | Dual-region AWS + version constraints |
| `backend.tf` | 14 | S3 native locking (ADR-006, no DynamoDB) |
| `variables.tf` | 149 | Input variables with validation |
| `main.tf` | 360 | 4 module compositions + SG + KMS grant |
| `outputs.tf` | 84 | Module output pass-through |
| `dev.tfvars` | 45 | Dev environment values |
| **Total** | **675** | |
