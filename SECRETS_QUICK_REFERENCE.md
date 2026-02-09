# Secrets Management Quick Reference

## Retrieving Secrets via AWS CLI

### RDS Database Username
```bash
aws secretsmanager get-secret-value \
  --secret-id pge-infrastructure-dev-db-username \
  --query SecretString \
  --output text
```

### RDS Database Password
```bash
aws secretsmanager get-secret-value \
  --secret-id pge-infrastructure-dev-db-password \
  --query SecretString \
  --output text
```

### GitHub Token
```bash
aws secretsmanager get-secret-value \
  --secret-id pge-infrastructure-dev-github-token \
  --query SecretString \
  --output text
```

## Retrieving Secrets in Application Code

### Python (boto3)
```python
import boto3
import json

def get_secret(secret_name):
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId=secret_name)
    return response['SecretString']

# Usage
db_username = get_secret('pge-infrastructure-dev-db-username')
db_password = get_secret('pge-infrastructure-dev-db-password')
```

### Node.js (AWS SDK v3)
```javascript
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

async function getSecret(secretName) {
    const client = new SecretsManagerClient({ region: "us-east-1" });
    const response = await client.send(
        new GetSecretValueCommand({ SecretId: secretName })
    );
    return response.SecretString;
}

// Usage
const dbUsername = await getSecret('pge-infrastructure-dev-db-username');
const dbPassword = await getSecret('pge-infrastructure-dev-db-password');
```

## ECS Task Definition with Secrets

### Example Task Definition
```json
{
  "containerDefinitions": [
    {
      "name": "app",
      "image": "your-image",
      "secrets": [
        {
          "name": "DB_USERNAME",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:pge-infrastructure-dev-db-username"
        },
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:pge-infrastructure-dev-db-password"
        }
      ]
    }
  ]
}
```

## Updating Secrets

### Update RDS Password
```bash
aws secretsmanager update-secret \
  --secret-id pge-infrastructure-dev-db-password \
  --secret-string "new-secure-password"
```

### Update GitHub Token
```bash
aws secretsmanager update-secret \
  --secret-id pge-infrastructure-dev-github-token \
  --secret-string "ghp_newtoken123456789"
```

## Rotating Secrets

### Enable Automatic Rotation for RDS
```bash
aws secretsmanager rotate-secret \
  --secret-id pge-infrastructure-dev-db-password \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789:function:SecretsManagerRDSRotation \
  --rotation-rules AutomaticallyAfterDays=90
```

## IAM Policy for Application Access

### Minimal Policy for ECS Task
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:*:secret:pge-infrastructure-dev-db-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:us-east-1:*:key/*"
    }
  ]
}
```

## Monitoring Secret Access

### CloudWatch Logs Insights Query
```
fields @timestamp, @message
| filter @message like /GetSecretValue/
| sort @timestamp desc
| limit 100
```

### CloudTrail Query for Secret Access
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=pge-infrastructure-dev-db-password \
  --max-results 50
```

## Terraform Outputs

### Get Secret ARNs
```bash
# RDS Username Secret ARN
terraform output db_username_secret_arn

# RDS Password Secret ARN
terraform output db_password_secret_arn

# GitHub Token Secret ARN (sensitive)
terraform output -json | jq -r '.github_token_secret_arn.value'
```

## Best Practices

1. **Never log secrets** - Ensure application logs don't contain secret values
2. **Use IAM roles** - Don't hardcode credentials in application code
3. **Rotate regularly** - Set up automatic rotation for production secrets
4. **Monitor access** - Enable CloudTrail and review secret access patterns
5. **Least privilege** - Grant only necessary permissions to access secrets
6. **Use environment-specific secrets** - Separate dev/staging/prod secrets
7. **Enable versioning** - Keep track of secret value changes
8. **Set up alerts** - Monitor for unauthorized access attempts

## Troubleshooting

### Secret Not Found
- Verify secret name matches exactly (case-sensitive)
- Check AWS region
- Verify IAM permissions

### Access Denied
- Check IAM policy has `secretsmanager:GetSecretValue`
- Verify KMS decrypt permissions
- Ensure resource ARN matches

### Decryption Failed
- Verify KMS key permissions
- Check if KMS key is enabled
- Ensure correct KMS key is used for encryption
