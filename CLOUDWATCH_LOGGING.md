# CloudWatch Logging Configuration Summary

## Overview
All modules are now configured to send logs to CloudWatch for centralized monitoring and analysis.

## Module-wise Logging Configuration

### 1. VPC Module
- **VPC Flow Logs**: Enabled and sent to CloudWatch log group `/aws/vpc/flowlogs/{project_name}`
- **Retention**: 14 days
- **Encryption**: KMS encrypted
- **Traffic Type**: ALL (accepted and rejected traffic)

### 2. ECS Module
- **Container Logs**: Sent to CloudWatch log group `/ecs/{project_name}-{environment}-app-logs`
- **Retention**: 7 days
- **Log Driver**: awslogs
- **Configuration**: Automatic log streaming from containers

### 3. ALB (Application Load Balancer)
- **Access Logs**: Stored in S3 bucket `{project_name}-{environment}-alb-logs-{account_id}`
- **Lifecycle**: Logs deleted after 30 days
- **Security**: Public access blocked, bucket policy configured
- **Content**: All HTTP/HTTPS requests and responses

### 4. RDS Aurora Cluster
- **CloudWatch Log Exports**: Enabled for:
  - Audit logs
  - Error logs
  - General logs
  - Slow query logs
- **Log Group**: `/aws/rds/{project_name}`
- **Retention**: 30 days
- **Encryption**: KMS encrypted

### 5. WAF (Web Application Firewall)
- **WAF Logs**: Sent to CloudWatch log group `aws-waf-logs-{project_name}-{environment}`
- **Retention**: 30 days
- **Content**: All blocked and allowed requests
- **Metrics**: CloudWatch metrics enabled for all rules

### 6. CodeBuild
- **Build Logs**: Sent to CloudWatch log group `/aws/codebuild/{project_name}`
- **Retention**: 14 days
- **Stream Name**: build-log
- **Content**: Build process logs and errors

### 7. CloudWatch Module
- **Application Logs**: `/aws/application/{project_name}` (30 days retention)
- **Security Logs**: `/aws/security/{project_name}` (90 days retention)
- **RDS Logs**: `/aws/rds/{project_name}` (30 days retention)

## CloudWatch Alarms Configured

### Application Performance
1. **ALB 5xx Errors**: Triggers when 5xx errors > 5 in 5 minutes
2. **ECS CPU High**: Triggers when CPU utilization > 80%
3. **ECS Memory High**: Triggers when memory utilization > 80%

### Database
4. **RDS Connections High**: Triggers when connections > 90

### Security
5. **WAF Blocked Requests**: Triggers when blocked requests > 100 in 5 minutes
6. **High Network Traffic**: Monitors unusual network patterns

### Network
7. **VPC Flow Logs**: Monitors all network traffic

## Alarm Actions
- All alarms send notifications to SNS topic
- Email notifications configured via SNS subscription

## Log Retention Policy
- VPC Flow Logs: 14 days
- ECS Container Logs: 7 days
- Application Logs: 30 days
- Security Logs: 90 days
- RDS Logs: 30 days
- WAF Logs: 30 days
- CodeBuild Logs: 14 days
- ALB Access Logs (S3): 30 days

## Encryption
- All CloudWatch log groups are encrypted using KMS
- KMS key ARN passed from KMS module
- S3 bucket for ALB logs has server-side encryption

## Monitoring Dashboard
- CloudWatch Dashboard created: `{project_name}-dashboard`
- Displays network traffic metrics
- Can be extended with additional widgets

## Best Practices Implemented
✅ Centralized logging to CloudWatch
✅ Appropriate retention periods based on log type
✅ KMS encryption for sensitive logs
✅ Structured log groups by service
✅ CloudWatch alarms for critical metrics
✅ SNS integration for alerting
✅ S3 lifecycle policies for cost optimization
✅ WAF logging for security monitoring
✅ RDS slow query logging enabled
✅ VPC flow logs for network analysis

## Cost Optimization
- Log retention periods set based on compliance requirements
- S3 lifecycle policies for ALB logs (30 days)
- Appropriate log group retention to balance cost and compliance
