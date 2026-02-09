# Secrets Management Summary

## Overview
All sensitive credentials and secrets are now stored in AWS Secrets Manager with KMS encryption.

## Secrets Inventory

### 1. RDS Database Secrets
**Location**: `modules/rds/main.tf`

#### DB Username Secret
- **Secret Name**: `{project_name}-{environment}-db-username`
- **Description**: Database master username
- **KMS Encryption**: ✅ Yes (using main KMS key from KMS module)
- **Recovery Window**: 7 days
- **Value Source**: Variable `var.db_username`
- **Secret ARN Output**: `module.rds.db_username_secret_arn`

#### DB Password Secret
- **Secret Name**: `{project_name}-{environment}-db-password`
- **Description**: Database master password
- **KMS Encryption**: ✅ Yes (using main KMS key from KMS module)
- **Recovery Window**: 7 days
- **Value Source**: Auto-generated random password (32 characters with special chars)
- **Secret ARN Output**: `module.rds.db_password_secret_arn`

**RDS Configuration**:
- Master username retrieved from Secrets Manager
- Master password retrieved from Secrets Manager
- RDS cluster encrypted with KMS
- CloudWatch logs exports enabled

---

### 2. GitHub OAuth Token
**Location**: `cicd/secrets.tf`

#### GitHub Token Secret
- **Secret Name**: `{project_name}-{environment}-github-token`
- **Description**: GitHub OAuth token for CodePipeline
- **KMS Encryption**: ✅ Yes (using dedicated CI/CD KMS key)
- **Recovery Window**: 7 days
- **Value Source**: Variable `var.github_token` (marked as sensitive)
- **Secret ARN Output**: `module.cicd.github_token_secret_arn` (sensitive)

**Usage**:
- CodePipeline retrieves token from Secrets Manager
- IAM permissions configured for `secretsmanager:GetSecretValue`
- KMS decrypt permissions added to CodePipeline role

---

## KMS Keys Inventory

### 1. Main KMS Key
**Location**: `modules/kms/main.tf`
**Purpose**: Encrypt RDS, CloudWatch logs, and other infrastructure secrets

**Configuration**:
- Key rotation: ✅ Enabled
- Deletion window: 7 days
- Alias: `alias/{project_name}-{environment}-key`
- Used by:
  - RDS Aurora cluster encryption
  - RDS Secrets Manager secrets
  - CloudWatch log groups
  - VPC Flow Logs

---

### 2. CI/CD KMS Key
**Location**: `cicd/kms.tf`
**Purpose**: Encrypt CI/CD pipeline secrets and artifacts

**Configuration**:
- Key rotation: ✅ Enabled
- Deletion window: 7 days
- Alias: `alias/{project_name}-{environment}-cicd-secrets`
- Used by:
  - GitHub token secret
  - CodePipeline S3 artifacts bucket
  - CodeBuild logs

---

## IAM Permissions for Secrets Access

### CodePipeline Role
**Permissions**:
```json
{
  "Effect": "Allow",
  "Action": ["secretsmanager:GetSecretValue"],
  "Resource": "arn:aws:secretsmanager:*:*:secret:{project_name}-{environment}-github-token"
}
{
  "Effect": "Allow",
  "Action": ["kms:Decrypt", "kms:DescribeKey", "kms:GenerateDataKey"],
  "Resource": "arn:aws:kms:*:*:key/{cicd-kms-key-id}"
}
```

### CodeBuild Role
**Permissions**:
```json
{
  "Effect": "Allow",
  "Action": ["kms:Decrypt", "kms:DescribeKey", "kms:GenerateDataKey"],
  "Resource": "*"
}
```

### ECS Task Execution Role
**Permissions**:
- CloudWatch Logs write access
- ECR image pull access
- Can be extended to access Secrets Manager for application secrets

---

## S3 Bucket Encryption

### CodePipeline Artifacts Bucket
- **Bucket Name**: `{project_name}-codepipeline-artifacts-{random_suffix}`
- **Encryption**: ✅ KMS (using CI/CD KMS key)
- **Algorithm**: aws:kms
- **Versioning**: ✅ Enabled
- **Public Access**: ❌ Blocked

### ALB Logs Bucket
- **Bucket Name**: `{project_name}-{environment}-alb-logs-{account_id}`
- **Encryption**: ✅ Server-side encryption
- **Lifecycle**: 30 days retention
- **Public Access**: ❌ Blocked

---

## Secrets Rotation

### Current Status
- **RDS Password**: Manual rotation (can be automated with Lambda)
- **GitHub Token**: Manual rotation required
- **KMS Keys**: Automatic key rotation enabled

### Recommendations for Production
1. Enable automatic secret rotation for RDS credentials
2. Implement Lambda function for GitHub token rotation
3. Set up CloudWatch alarms for secret access patterns
4. Enable AWS Config rules for secrets compliance

---

## Security Best Practices Implemented

✅ **Encryption at Rest**
- All secrets encrypted with KMS
- Separate KMS keys for different purposes
- Key rotation enabled

✅ **Encryption in Transit**
- Secrets retrieved via AWS API (TLS)
- No secrets in Terraform state (references only)

✅ **Access Control**
- Least privilege IAM policies
- Resource-specific permissions where possible
- Sensitive outputs marked appropriately

✅ **Audit & Monitoring**
- CloudWatch logs for secret access
- KMS key usage can be monitored
- Recovery window for accidental deletion

✅ **Secret Lifecycle**
- 7-day recovery window for deleted secrets
- Automatic password generation for RDS
- Version control for secret values

---

## Secrets Access Patterns

### Application Access to RDS
```
ECS Task → IAM Role → Secrets Manager → KMS Decrypt → RDS Credentials
```

### CodePipeline GitHub Access
```
CodePipeline → IAM Role → Secrets Manager → KMS Decrypt → GitHub Token
```

### RDS Cluster Access
```
RDS Cluster → Secrets Manager (username/password) → KMS Encrypted Storage
```

---

## Compliance & Governance

### Secret Naming Convention
Format: `{project_name}-{environment}-{secret_type}`

Examples:
- `pge-infrastructure-dev-db-username`
- `pge-infrastructure-dev-db-password`
- `pge-infrastructure-dev-github-token`

### Tagging Strategy
All secrets tagged with:
- `Name`: Descriptive name
- `Environment`: dev/staging/prod
- `Project`: Project name
- `ManagedBy`: Terraform

---

## Outputs Available

### From RDS Module
- `db_username_secret_arn`: ARN of DB username secret
- `db_password_secret_arn`: ARN of DB password secret

### From CI/CD Module
- `github_token_secret_arn`: ARN of GitHub token (sensitive)
- `cicd_kms_key_arn`: ARN of CI/CD KMS key
- `cicd_kms_key_id`: ID of CI/CD KMS key

### From KMS Module
- `kms_key_arn`: ARN of main KMS key
- `kms_key_id`: ID of main KMS key

---

## Future Enhancements

1. **Automatic Rotation**
   - Implement Lambda for RDS password rotation
   - Set up rotation schedule (e.g., every 90 days)

2. **Additional Secrets**
   - API keys for third-party services
   - SSL/TLS certificates
   - Application configuration secrets

3. **Secret Scanning**
   - Implement git-secrets or similar tools
   - Prevent secrets from being committed to repository

4. **Cross-Region Replication**
   - Replicate critical secrets to DR region
   - Ensure availability during regional failures

5. **Monitoring & Alerting**
   - CloudWatch alarms for unauthorized access attempts
   - SNS notifications for secret rotation failures
   - AWS Config rules for compliance monitoring
