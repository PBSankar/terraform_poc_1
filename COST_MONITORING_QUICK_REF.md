# Cost Monitoring Quick Reference

## Daily Cost Checks

### View Current Month Costs
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

### View Costs by Service
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "7 days ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

### View Costs by Tag
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "30 days ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

## Budget Management

### Check Budget Status
```bash
aws budgets describe-budgets \
  --account-id $(aws sts get-caller-identity --query Account --output text)
```

### View Budget Alerts
```bash
aws budgets describe-notifications-for-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name pge-infrastructure-dev-monthly-budget
```

## Cost Anomaly Detection

### List Anomalies
```bash
aws ce get-anomalies \
  --date-interval Start=$(date -d "7 days ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --max-results 10
```

### Get Anomaly Details
```bash
aws ce get-anomaly-monitors
```

## Resource Tagging

### Find Untagged Resources
```bash
# EC2 instances without required tags
aws ec2 describe-instances \
  --query 'Reservations[].Instances[?!Tags || !contains(Tags[].Key, `Project`)].[InstanceId]' \
  --output table

# RDS instances without tags
aws rds describe-db-instances \
  --query 'DBInstances[?!TagList || length(TagList) == `0`].[DBInstanceIdentifier]' \
  --output table
```

### Add Tags to Resources
```bash
# Tag EC2 instance
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Project,Value=pge Key=Environment,Value=dev

# Tag RDS instance
aws rds add-tags-to-resource \
  --resource-name arn:aws:rds:region:account:db:instance-name \
  --tags Key=Project,Value=pge Key=Environment,Value=dev
```

## Cost Optimization Actions

### Stop Non-Production Resources (After Hours)
```bash
# Stop ECS service
aws ecs update-service \
  --cluster pge-infrastructure-dev-cluster \
  --service pge-infrastructure-dev-app-svc \
  --desired-count 0

# Stop RDS cluster
aws rds stop-db-cluster \
  --db-cluster-identifier pge-infrastructure-dev-aurora-cluster
```

### Start Resources (Business Hours)
```bash
# Start ECS service
aws ecs update-service \
  --cluster pge-infrastructure-dev-cluster \
  --service pge-infrastructure-dev-app-svc \
  --desired-count 2

# Start RDS cluster
aws rds start-db-cluster \
  --db-cluster-identifier pge-infrastructure-dev-aurora-cluster
```

### Delete Unused Resources
```bash
# List unused EBS volumes
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table

# Delete unused snapshots older than 30 days
aws ec2 describe-snapshots \
  --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '30 days ago' --iso-8601)'].[SnapshotId]" \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id
```

## CloudWatch Metrics

### View ECS Task Count
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name RunningTaskCount \
  --dimensions Name=ClusterName,Value=pge-infrastructure-dev-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### View RDS CPU Utilization
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBClusterIdentifier,Value=pge-infrastructure-dev-aurora-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## Cost Reports

### Generate Monthly Report
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost UnblendedCost \
  --group-by Type=SERVICE \
  --output json > monthly-cost-report.json
```

### Generate Cost Forecast
```bash
aws ce get-cost-forecast \
  --time-period Start=$(date +%Y-%m-%d),End=$(date -d "+30 days" +%Y-%m-%d) \
  --metric BLENDED_COST \
  --granularity MONTHLY
```

## Terraform Commands

### View Cost-Related Outputs
```bash
terraform output budget_name
terraform output cost_anomaly_monitor_arn
terraform output monthly_budget_limit
```

### Update Budget Limit
```bash
# Edit terraform.tfvars
echo 'monthly_budget_limit = 1500' >> terraform.tfvars

# Apply changes
terraform apply -target=module.cost_monitoring
```

## Alerts & Notifications

### Test SNS Topic
```bash
aws sns publish \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --subject "Test Cost Alert" \
  --message "This is a test cost alert notification"
```

### Subscribe to Budget Alerts
```bash
aws budgets create-notification \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget-name pge-infrastructure-dev-monthly-budget \
  --notification NotificationType=ACTUAL,ComparisonOperator=GREATER_THAN,Threshold=80 \
  --subscriber SubscriptionType=EMAIL,Address=your-email@example.com
```

## Cost Optimization Tips

### Right-Size ECS Tasks
```bash
# View ECS task metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=pge-infrastructure-dev-app-svc \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Average,Maximum

# If average CPU < 30%, consider reducing task size
```

### Identify Idle Resources
```bash
# Find idle load balancers (no requests)
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerArn,LoadBalancerName]' \
  --output text | while read arn name; do
    requests=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApplicationELB \
      --metric-name RequestCount \
      --dimensions Name=LoadBalancer,Value=${arn##*/} \
      --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 604800 \
      --statistics Sum \
      --query 'Datapoints[0].Sum' \
      --output text)
    if [ "$requests" == "0.0" ] || [ "$requests" == "None" ]; then
      echo "Idle ALB: $name"
    fi
  done
```

## Monthly Cost Review Checklist

- [ ] Review total monthly spend vs budget
- [ ] Identify top 5 cost drivers
- [ ] Check for cost anomalies
- [ ] Review unused resources
- [ ] Validate resource tags
- [ ] Check auto-scaling effectiveness
- [ ] Review RDS utilization
- [ ] Analyze data transfer costs
- [ ] Update budget if needed
- [ ] Document optimization actions
