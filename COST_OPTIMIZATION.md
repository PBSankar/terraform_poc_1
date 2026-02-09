# Cost Optimization & Resource Tagging Strategy

## Overview
Comprehensive cost optimization strategy with resource tagging, budgets, anomaly detection, and monitoring.

---

## 1. Resource Tagging Strategy

### Standard Tags Applied to All Resources

```hcl
{
  Environment  = "dev"              # Environment identifier
  Project      = "pge"              # Project name
  Owner        = "trianz"           # Team/Owner
  ManagedBy    = "Terraform"        # Management tool
  CostCenter   = "Engineering"      # Cost allocation
  Application  = "PGE-Infrastructure" # Application name
  Compliance   = "Required"         # Compliance requirement
  c-modernize  = "true"             # Modernization flag
}
```

### Tag Categories

#### 1. **Operational Tags**
- `Environment`: dev, staging, prod
- `ManagedBy`: Terraform, Manual
- `Application`: Application identifier

#### 2. **Financial Tags**
- `CostCenter`: Department/team for cost allocation
- `Project`: Project identifier for billing
- `Owner`: Responsible team/person

#### 3. **Compliance Tags**
- `Compliance`: Required, Optional
- `DataClassification`: Public, Internal, Confidential
- `BackupPolicy`: Daily, Weekly, None

#### 4. **Technical Tags**
- `Module`: vpc, ecs, rds, etc.
- `Version`: Resource version
- `AutoShutdown`: true/false (for non-prod)

### Tag Enforcement

**AWS Config Rules** (Recommended):
```hcl
# Ensure all resources have required tags
required-tags = [
  "Environment",
  "Project",
  "Owner",
  "ManagedBy",
  "CostCenter"
]
```

---

## 2. Cost Monitoring Components

### A. AWS Budgets

**Configuration**: `modules/cost-monitoring/main.tf`

```hcl
Monthly Budget: $1,000 (configurable)
Alerts:
  - 80% threshold (actual)
  - 100% threshold (actual)
  - 90% threshold (forecasted)
```

**Features**:
- Filtered by Project and Environment tags
- Email notifications at multiple thresholds
- Forecasted cost alerts

**Customization**:
```hcl
variable "monthly_budget_limit" {
  default = 1000  # Adjust per environment
}
```

### B. Cost Anomaly Detection

**Service Monitor**:
- Monitors all AWS services
- Dimensional analysis
- Daily frequency

**Anomaly Threshold**:
- Alerts when anomaly impact ≥ $100
- Email notifications
- Daily summary reports

**Benefits**:
- Automatic detection of unusual spending
- Service-level granularity
- Proactive cost management

### C. CloudWatch Billing Alarm

**Configuration**:
```hcl
Metric: EstimatedCharges
Threshold: $50/day (configurable)
Period: 6 hours
Action: SNS notification
```

**Purpose**:
- Real-time cost monitoring
- Daily spending alerts
- Integration with existing SNS topics

---

## 3. Cost Allocation Tags

### Activation Required

**AWS Console Steps**:
1. Go to Billing → Cost Allocation Tags
2. Activate tags:
   - `Project`
   - `Environment`
   - `CostCenter`
   - `Owner`
   - `Application`

**CLI Command**:
```bash
aws ce update-cost-allocation-tags-status \
  --cost-allocation-tags-status \
  TagKey=Project,Status=Active \
  TagKey=Environment,Status=Active \
  TagKey=CostCenter,Status=Active
```

### Cost Reports by Tag

**Example Queries**:
```bash
# Cost by Project
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project

# Cost by Environment
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

---

## 4. Cost Optimization Strategies

### A. Compute Optimization

#### ECS Fargate
**Current**:
- CPU: 256 units
- Memory: 512 MiB
- Scaling: 1-4 tasks

**Optimization**:
```hcl
# Use Fargate Spot for non-critical workloads
capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  weight           = 70
  base             = 0
}

capacity_provider_strategy {
  capacity_provider = "FARGATE"
  weight           = 30
  base             = 1
}
```

**Savings**: Up to 70% on compute costs

#### Scheduled Scaling
**Implemented**:
- Scale down after hours (6 PM - 8 AM)
- Weekend scale down
- Business hours scale up

**Estimated Savings**: 30-40% on ECS costs

### B. Database Optimization

#### RDS Aurora
**Current Configuration**:
- Instance: db.t4g.medium
- Count: 2 (writer + reader)
- Backup: 7 days

**Optimization Options**:

1. **Aurora Serverless v2** (for variable workloads):
```hcl
engine_mode = "provisioned"
serverlessv2_scaling_configuration {
  min_capacity = 0.5
  max_capacity = 2
}
```

2. **Reserved Instances** (for production):
- 1-year term: 30% savings
- 3-year term: 50% savings

3. **Backup Optimization**:
```hcl
backup_retention_period = 7  # Reduce for dev/test
skip_final_snapshot    = true # For non-prod
```

### C. Storage Optimization

#### S3 Lifecycle Policies
**ALB Logs**:
```hcl
lifecycle_rule {
  enabled = true
  
  transition {
    days          = 30
    storage_class = "STANDARD_IA"
  }
  
  transition {
    days          = 90
    storage_class = "GLACIER"
  }
  
  expiration {
    days = 365
  }
}
```

**Savings**: 50-80% on storage costs

#### EBS Optimization
- Use gp3 instead of gp2 (20% cheaper)
- Delete unused snapshots
- Enable EBS snapshot lifecycle

### D. Network Optimization

#### NAT Gateway
**Current**: 1 NAT Gateway per AZ

**Optimization**:
```hcl
# For dev/test: Use single NAT Gateway
nat_gateway_count = var.environment == "prod" ? var.az_count : 1
```

**Savings**: $32-45/month per NAT Gateway

#### VPC Endpoints
**Implemented**: ECR, S3, CloudWatch, Secrets Manager

**Benefit**: Eliminate NAT Gateway data transfer costs

---

## 5. Cost Monitoring Dashboard

### CloudWatch Dashboard

**Metrics to Track**:
1. **Estimated Charges** (Billing)
2. **ECS Task Count** (ECS)
3. **RDS CPU/Memory** (RDS)
4. **ALB Request Count** (ALB)
5. **NAT Gateway Bytes** (VPC)

**Example Dashboard**:
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Billing", "EstimatedCharges", {"stat": "Maximum"}]
        ],
        "period": 21600,
        "stat": "Maximum",
        "region": "us-east-1",
        "title": "Estimated Charges"
      }
    }
  ]
}
```

---

## 6. Cost Allocation Reports

### Monthly Cost Report by Service

```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost UnblendedCost \
  --group-by Type=SERVICE
```

### Cost by Tag

```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment \
  --filter file://filter.json
```

**filter.json**:
```json
{
  "Tags": {
    "Key": "Project",
    "Values": ["pge"]
  }
}
```

---

## 7. Cost Optimization Checklist

### Immediate Actions
- [x] Implement resource tagging strategy
- [x] Set up AWS Budgets with alerts
- [x] Enable cost anomaly detection
- [x] Configure CloudWatch billing alarms
- [x] Implement scheduled scaling for ECS
- [x] Add S3 lifecycle policies for logs
- [x] Use VPC endpoints to reduce NAT costs

### Short-term (1-3 months)
- [ ] Analyze cost reports and identify top spenders
- [ ] Right-size ECS tasks based on actual usage
- [ ] Consider Aurora Serverless for variable workloads
- [ ] Implement Fargate Spot for non-critical tasks
- [ ] Review and delete unused resources
- [ ] Enable AWS Cost Explorer recommendations

### Long-term (3-6 months)
- [ ] Purchase Reserved Instances for production RDS
- [ ] Implement Savings Plans for compute
- [ ] Set up automated resource cleanup
- [ ] Implement cost allocation by feature/team
- [ ] Create cost optimization runbooks
- [ ] Quarterly cost review meetings

---

## 8. Cost Estimation

### Monthly Cost Breakdown (Estimated)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| ECS Fargate | 2 tasks × 0.5 vCPU × 1GB | $30-40 |
| RDS Aurora | 2 × db.t4g.medium | $150-200 |
| ALB | 1 ALB + data transfer | $20-30 |
| NAT Gateway | 1 gateway + data | $35-50 |
| VPC Endpoints | 4 endpoints | $30-40 |
| S3 | Logs + artifacts | $5-10 |
| CloudWatch | Logs + metrics | $10-20 |
| Secrets Manager | 5 secrets | $2-3 |
| KMS | 2 keys | $2 |
| WAF | 1 ACL + rules | $10-15 |
| **Total** | | **$294-410** |

### Cost Optimization Potential

| Optimization | Savings | Implementation |
|--------------|---------|----------------|
| Scheduled Scaling | 30-40% ECS | ✅ Implemented |
| Fargate Spot | 70% on spot tasks | Recommended |
| Single NAT (dev) | $35/month | Recommended |
| S3 Lifecycle | 50% storage | ✅ Implemented |
| Reserved RDS | 30-50% RDS | Long-term |
| **Total Potential** | **$100-150/month** | |

---

## 9. Alerts Configuration

### Budget Alerts
- **80% threshold**: Warning notification
- **100% threshold**: Critical notification
- **90% forecasted**: Proactive alert

### Anomaly Alerts
- **Threshold**: $100 impact
- **Frequency**: Daily
- **Delivery**: Email

### CloudWatch Alarms
- **Estimated charges**: Daily threshold
- **ECS CPU/Memory**: Performance alerts
- **RDS connections**: Capacity alerts

---

## 10. Best Practices

### Tagging
1. Apply tags at resource creation
2. Use consistent naming conventions
3. Automate tag enforcement with AWS Config
4. Regular tag audits

### Monitoring
1. Review cost reports weekly
2. Investigate anomalies immediately
3. Track cost trends over time
4. Set realistic budgets per environment

### Optimization
1. Right-size resources based on metrics
2. Use spot instances where possible
3. Implement auto-scaling
4. Regular cleanup of unused resources
5. Leverage AWS Cost Explorer recommendations

### Governance
1. Require cost approval for new resources
2. Implement cost allocation by team
3. Regular cost review meetings
4. Document cost optimization decisions

---

## 11. Terraform Outputs

```bash
# View cost monitoring resources
terraform output budget_name
terraform output anomaly_monitor_arn

# View resource tags
terraform show | grep tags -A 10
```

---

## 12. Additional Resources

- **AWS Cost Explorer**: https://console.aws.amazon.com/cost-management/
- **AWS Budgets**: https://console.aws.amazon.com/billing/home#/budgets
- **Cost Optimization Hub**: https://console.aws.amazon.com/cost-optimization-hub/
- **AWS Pricing Calculator**: https://calculator.aws/
