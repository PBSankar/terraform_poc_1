# PGE Infrastructure - Complete Architecture Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Network Architecture](#network-architecture)
3. [Application Architecture](#application-architecture)
4. [Data Architecture](#data-architecture)
5. [Security Architecture](#security-architecture)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Monitoring & Observability](#monitoring--observability)
8. [Cost Analysis](#cost-analysis)
9. [Resource Inventory](#resource-inventory)

---

## Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Internet Users                                  │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │      AWS WAF           │
                    │  - Rate Limiting       │
                    │  - OWASP Rules         │
                    │  - Bad Input Filter    │
                    └───────────┬────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                           AWS Region (us-east-1)                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                                    │ │
│  │                                                                         │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │              Public Subnets (2 AZs)                              │ │ │
│  │  │  ┌────────────────────────────────────────────────────────┐     │ │ │
│  │  │  │  Application Load Balancer (ALB)                       │     │ │ │
│  │  │  │  - Distributed across 2 Public Subnets                 │     │ │ │
│  │  │  │  - HTTP/HTTPS Listeners                                │     │ │ │
│  │  │  │  - Health Checks                                       │     │ │ │
│  │  │  │  - Session Stickiness                                  │     │ │ │
│  │  │  │  - Access Logs → S3                                    │     │ │ │
│  │  │  └────────────────────────────────────────────────────────┘     │ │ │
│  │  │  ┌────────────────────────────────────────────────────────┐     │ │ │
│  │  │  │  NAT Gateway 1 (AZ-1)  │  NAT Gateway 2 (AZ-2)         │     │ │ │
│  │  │  └────────────────────────────────────────────────────────┘     │ │ │
│  │  └──────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                         │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │              Private Subnets (2 AZs)                             │ │ │
│  │  │  ┌────────────────────────────────────────────────────────┐     │ │ │
│  │  │  │  ECS Fargate Cluster                                   │     │ │ │
│  │  │  │  ┌──────────────┐  ┌──────────────┐                   │     │ │ │
│  │  │  │  │ ECS Task 1   │  │ ECS Task 2   │                   │     │ │ │
│  │  │  │  │ - Container  │  │ - Container  │                   │     │ │ │
│  │  │  │  │ - Task Role  │  │ - Task Role  │                   │     │ │ │
│  │  │  │  └──────────────┘  └──────────────┘                   │     │ │ │
│  │  │  │  Auto Scaling: 1-4 tasks                              │     │ │ │
│  │  │  └────────────────────────────────────────────────────────┘     │ │ │
│  │  │  ┌────────────────────────────────────────────────────────┐     │ │ │
│  │  │  │  RDS Aurora MySQL Cluster                             │     │ │ │
│  │  │  │  ┌──────────────┐  ┌──────────────┐                   │     │ │ │
│  │  │  │  │ Writer       │  │ Reader       │                   │     │ │ │
│  │  │  │  │ Instance     │  │ Instance     │                   │     │ │ │
│  │  │  │  └──────────────┘  └──────────────┘                   │     │ │ │
│  │  │  │         ▲                                              │     │ │ │
│  │  │  │         │                                              │     │ │ │
│  │  │  │  ┌──────┴───────┐                                     │     │ │ │
│  │  │  │  │  RDS Proxy   │                                     │     │ │ │
│  │  │  │  │  Connection  │                                     │     │ │ │
│  │  │  │  │  Pooling     │                                     │     │ │ │
│  │  │  │  └──────────────┘                                     │     │ │ │
│  │  │  └────────────────────────────────────────────────────────┘     │ │ │
│  │  │  ┌────────────────────────────────────────────────────────┐     │ │ │
│  │  │  │  VPC Endpoints                                         │     │ │ │
│  │  │  │  - ECR API/DKR                                         │     │ │ │
│  │  │  │  - S3                                                  │     │ │ │
│  │  │  │  - CloudWatch Logs                                     │     │ │ │
│  │  │  │  - Secrets Manager                                     │     │ │ │
│  │  │  └────────────────────────────────────────────────────────┘     │ │ │
│  │  └──────────────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                      Supporting Services                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │ ECR          │  │ Secrets      │  │ KMS Keys     │                 │ │
│  │  │ Repository   │  │ Manager      │  │ - Main       │                 │ │
│  │  │              │  │ - DB Creds   │  │ - CI/CD      │                 │ │
│  │  └──────────────┘  │ - GitHub     │  └──────────────┘                 │ │
│  │                    │   Token      │                                    │ │
│  │                    └──────────────┘                                    │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                   Monitoring & Logging                                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │ CloudWatch   │  │ SNS Topics   │  │ Cost         │                 │ │
│  │  │ - Logs       │  │ - Alarms     │  │ Monitoring   │                 │ │
│  │  │ - Metrics    │  │ - Alerts     │  │ - Budgets    │                 │ │
│  │  │ - Alarms     │  │              │  │ - Anomalies  │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                        CI/CD Pipeline                                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │ │
│  │  │ GitHub       │→ │ CodePipeline │→ │ CodeBuild    │→ ECR → ECS      │ │
│  │  │ Repository   │  │              │  │              │                 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                 │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────────┘
```

### Architecture Principles

1. **High Availability**: Multi-AZ deployment for critical components
2. **Security**: Defense in depth with WAF, security groups, NACLs, encryption
3. **Scalability**: Auto-scaling for compute and database read replicas
4. **Cost Optimization**: Scheduled scaling, lifecycle policies, resource tagging
5. **Observability**: Comprehensive logging, monitoring, and alerting
6. **Automation**: Infrastructure as Code with Terraform, CI/CD pipeline

---

## Network Architecture

### VPC Design

**CIDR Block**: 10.0.0.0/16 (65,536 IPs)

#### Subnet Layout

```
VPC: 10.0.0.0/16
├── Public Subnet 1 (AZ-1): 10.0.0.0/24 (256 IPs)
│   ├── ALB (Primary)
│   ├── NAT Gateway 1
│   └── Internet Gateway
├── Public Subnet 2 (AZ-2): 10.0.1.0/24 (256 IPs)
│   ├── ALB (Secondary)
│   ├── NAT Gateway 2
│   └── Internet Gateway
├── Private Subnet 1 (AZ-1): 10.0.2.0/24 (256 IPs)
│   ├── ECS Tasks
│   ├── RDS Writer
│   └── VPC Endpoints
└── Private Subnet 2 (AZ-2): 10.0.3.0/24 (256 IPs)
    ├── ECS Tasks
    ├── RDS Reader
    └── VPC Endpoints
```

### Network Flow Diagram

```
Internet → Route53 (Optional) → WAF → ALB (Public Subnet)
                                        ↓
                              Target Group Health Check
                                        ↓
                        ECS Tasks (Private Subnets)
                                        ↓
                              RDS Proxy (Private)
                                        ↓
                        Aurora Cluster (Private Subnets)

Outbound Traffic:
ECS Tasks (AZ-1) → NAT Gateway 1 → Internet Gateway → Internet
ECS Tasks (AZ-2) → NAT Gateway 2 → Internet Gateway → Internet
ECS Tasks → VPC Endpoints → AWS Services (Private)
```

### Security Groups

```
┌─────────────────────────────────────────────────────────────┐
│ Web Security Group (ALB)                                    │
│ Inbound:  0.0.0.0/0:80, 0.0.0.0/0:443                      │
│ Outbound: App SG:80                                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ App Security Group (ECS Tasks)                              │
│ Inbound:  Web SG:80                                         │
│ Outbound: DB SG:3306, VPC Endpoint SG:443, 0.0.0.0/0:*    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Database Security Group (RDS)                               │
│ Inbound:  App SG:3306                                       │
│ Outbound: None                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ VPC Endpoint Security Group                                 │
│ Inbound:  App SG:443                                        │
│ Outbound: None                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Application Architecture

### Request Flow

```
1. User Request
   ↓
2. DNS Resolution (Optional Route53)
   ↓
3. AWS WAF
   ├─ Rate Limiting Check (2000 req/5min)
   ├─ OWASP Top 10 Rules
   └─ Known Bad Inputs Filter
   ↓
4. Application Load Balancer
   ├─ SSL/TLS Termination (if HTTPS)
   ├─ Health Check (/)
   ├─ Session Stickiness (24h)
   └─ Access Logging → S3
   ↓
5. Target Group
   ├─ Round Robin Distribution
   └─ Deregistration Delay (30s)
   ↓
6. ECS Fargate Tasks
   ├─ Container Health Check
   ├─ Application Processing
   ├─ Secrets from Secrets Manager
   └─ Logs → CloudWatch
   ↓
7. RDS Proxy (Connection Pooling)
   ├─ Connection Reuse
   ├─ Automatic Failover
   └─ TLS Encryption
   ↓
8. Aurora MySQL Cluster
   ├─ Writer Instance (Writes)
   ├─ Reader Instance (Reads)
   └─ Automatic Backups
   ↓
9. Response Path (Reverse)
```

### ECS Task Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ ECS Task Definition                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Container                                               │ │
│ │ - Image: ECR Repository                                │ │
│ │ - CPU: 256 units (0.25 vCPU)                          │ │
│ │ - Memory: 512 MiB                                      │ │
│ │ - Port: 80                                             │ │
│ │ - Health Check: curl localhost/                       │ │
│ │ - Environment Variables                                │ │
│ │ - Secrets: DB credentials from Secrets Manager        │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Task Execution Role                                     │ │
│ │ - Pull images from ECR                                 │ │
│ │ - Write logs to CloudWatch                             │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Task Role (Application Permissions)                     │ │
│ │ - Read secrets from Secrets Manager                    │ │
│ │ - Decrypt with KMS                                     │ │
│ │ - Read/Write S3 objects                                │ │
│ │ - Write CloudWatch logs                                │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Auto Scaling Configuration

```
ECS Service Auto Scaling
├── Target Tracking Policies
│   ├── CPU Utilization: 70% target
│   ├── Memory Utilization: 80% target
│   └── ALB Request Count: 1000 requests/target
├── Scheduled Scaling
│   ├── Scale Up: 8 AM Mon-Fri (min=1, max=4)
│   └── Scale Down: 6 PM Mon-Fri (min=1, max=4)
└── Capacity
    ├── Minimum: 1 task
    ├── Desired: 1 task
    └── Maximum: 4 tasks
```


---

## Data Architecture

### Database Configuration

```
Aurora MySQL Cluster
├── Engine: aurora-mysql 8.0.mysql_aurora.3.04.0
├── Instances
│   ├── Writer Instance
│   │   ├── Class: db.t4g.medium (2 vCPU, 4 GB RAM)
│   │   ├── Role: Read/Write operations
│   │   └── Promotion Tier: 0
│   └── Reader Instance
│       ├── Class: db.t4g.medium (2 vCPU, 4 GB RAM)
│       ├── Role: Read-only operations
│       └── Promotion Tier: 1
├── Storage
│   ├── Type: Aurora Storage (auto-scaling)
│   ├── Encryption: KMS encrypted
│   └── Backup: 7 days retention
├── Networking
│   ├── Subnet Group: Private subnets (2 AZs)
│   ├── Security Group: Database SG
│   └── Port: 3306
└── Features
    ├── CloudWatch Log Exports: audit, error, general, slowquery
    ├── Automatic Backups: Daily
    └── Preferred Backup Window: 07:00-09:00 UTC
```

### RDS Proxy Configuration

```
RDS Proxy
├── Purpose: Connection pooling and management
├── Engine Family: MYSQL
├── Authentication: Secrets Manager
├── Connection Pool
│   ├── Max Connections: 100%
│   ├── Max Idle Connections: 50%
│   └── Borrow Timeout: 120 seconds
├── Security
│   ├── TLS: Required
│   ├── IAM Auth: Disabled
│   └── Secrets: DB username/password
└── Benefits
    ├── Connection reuse
    ├── Reduced latency
    ├── Automatic failover
    └── Better scalability
```

### Data Flow

```
Application → RDS Proxy → Aurora Cluster
                ↓              ↓
         Connection Pool   Writer/Reader
                ↓              ↓
         Reuse Connections  Data Storage
                              ↓
                        Automatic Backups
                              ↓
                        S3 (Backup Storage)
```

### Secrets Management

```
Secrets Manager
├── Database Username
│   ├── Secret Name: {project}-{env}-db-username
│   ├── KMS Encryption: Main KMS Key
│   └── Recovery Window: 7 days
├── Database Password
│   ├── Secret Name: {project}-{env}-db-password
│   ├── Value: Auto-generated (32 chars)
│   ├── KMS Encryption: Main KMS Key
│   └── Recovery Window: 7 days
└── GitHub Token
    ├── Secret Name: {project}-{env}-github-token
    ├── KMS Encryption: CI/CD KMS Key
    └── Recovery Window: 7 days
```

---

## Security Architecture

### Defense in Depth Layers

```
Layer 1: Network Security
├── WAF (Application Layer)
│   ├── Rate Limiting: 2000 req/5min per IP
│   ├── AWS Managed Rules: Common Rule Set
│   ├── Known Bad Inputs: Malicious pattern detection
│   └── Logging: CloudWatch Logs
├── Network ACLs
│   ├── Public Subnets: Allow HTTP/HTTPS inbound
│   └── Private Subnets: Allow internal traffic
└── Security Groups (Stateful)
    ├── Web SG: Internet → ALB
    ├── App SG: ALB → ECS Tasks
    ├── DB SG: ECS Tasks → RDS
    └── VPC Endpoint SG: ECS Tasks → AWS Services

Layer 2: Identity & Access Management
├── IAM Roles
│   ├── ECS Task Execution Role
│   ├── ECS Task Role (Application)
│   ├── RDS Proxy Role
│   ├── CodePipeline Role
│   └── CodeBuild Role
├── Least Privilege Policies
└── No Hardcoded Credentials

Layer 3: Data Encryption
├── At Rest
│   ├── RDS: KMS encrypted
│   ├── S3: KMS encrypted
│   ├── Secrets Manager: KMS encrypted
│   ├── CloudWatch Logs: KMS encrypted
│   └── EBS Volumes: Encrypted
└── In Transit
    ├── ALB → ECS: Internal VPC
    ├── ECS → RDS Proxy: TLS required
    ├── RDS Proxy → Aurora: TLS
    └── All AWS API calls: TLS 1.2+

Layer 4: Application Security
├── Container Image Scanning
│   ├── ECR: Scan on push enabled
│   └── Vulnerability detection
├── Health Checks
│   ├── Container: curl localhost/
│   ├── ALB Target Group: HTTP /
│   └── ECS Service: 60s grace period
└── Deployment Safety
    ├── Circuit Breaker: Auto-rollback
    └── Minimum Healthy: 100%

Layer 5: Monitoring & Logging
├── VPC Flow Logs → CloudWatch
├── ALB Access Logs → S3
├── WAF Logs → CloudWatch
├── Application Logs → CloudWatch
├── RDS Logs → CloudWatch
└── CloudTrail: API audit logs
```

### KMS Key Architecture

```
Main KMS Key
├── Purpose: Infrastructure encryption
├── Key Rotation: Enabled
├── Used By
│   ├── RDS Aurora Cluster
│   ├── RDS Secrets (username/password)
│   ├── CloudWatch Log Groups
│   └── VPC Flow Logs
└── Alias: {project}-{environment}-key

CI/CD KMS Key
├── Purpose: CI/CD secrets encryption
├── Key Rotation: Enabled
├── Used By
│   ├── GitHub Token Secret
│   ├── CodePipeline S3 Bucket
│   └── CodeBuild Artifacts
└── Alias: {project}-{environment}-cicd-secrets
```

---

## CI/CD Pipeline

### Pipeline Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. Source Stage                                                  │
│    GitHub Repository (apache_docker)                             │
│    ├── Branch: main                                              │
│    ├── Trigger: Push to main                                     │
│    └── Authentication: OAuth Token (Secrets Manager)             │
└────────────────────────┬─────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────────┐
│ 2. Build Stage                                                   │
│    CodeBuild Project                                             │
│    ├── Build Spec: buildspec.yml                                │
│    ├── Environment: Amazon Linux 2                              │
│    ├── Compute: BUILD_GENERAL1_MEDIUM                           │
│    ├── Privileged Mode: Enabled (Docker)                        │
│    ├── Steps                                                     │
│    │   ├── Pre-build: ECR login                                 │
│    │   ├── Build: Docker build                                  │
│    │   ├── Post-build: Docker push to ECR                       │
│    │   └── Tag: latest                                          │
│    └── Logs: CloudWatch Logs                                    │
└────────────────────────┬─────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────────────┐
│ 3. Deploy Stage                                                  │
│    ECS Deployment                                                │
│    ├── Cluster: {project}-{environment}-cluster                 │
│    ├── Service: {project}-{environment}-app-svc                 │
│    ├── Task Definition: Updated with new image                  │
│    ├── Deployment Type: Rolling update                          │
│    ├── Circuit Breaker: Enabled with rollback                   │
│    └── Health Check: 60s grace period                           │
└──────────────────────────────────────────────────────────────────┘
```

### Artifact Storage

```
S3 Bucket: {project}-codepipeline-artifacts-{random}
├── Encryption: KMS (CI/CD Key)
├── Versioning: Enabled
├── Lifecycle: Not configured (manual cleanup)
└── Access: CodePipeline and CodeBuild roles only
```

### Build Environment Variables

```
AWS_DEFAULT_REGION: us-east-1
AWS_ACCOUNT_ID: {account_id}
IMAGE_REPO_NAME: {repository_name}
IMAGE_TAG: latest
ECS_CLUSTER_NAME: {project}-cluster
ECS_SERVICE_NAME: {project}-service
```

---

## Monitoring & Observability

### CloudWatch Log Groups

```
Log Groups
├── /aws/vpc/flowlogs/{project}
│   ├── Retention: 14 days
│   ├── Encryption: KMS
│   └── Content: VPC flow logs (all traffic)
├── /ecs/{project}-{environment}-app-logs
│   ├── Retention: 7 days
│   ├── Encryption: None
│   └── Content: Container application logs
├── /aws/application/{project}
│   ├── Retention: 30 days
│   ├── Encryption: KMS
│   └── Content: Application-level logs
├── /aws/security/{project}
│   ├── Retention: 90 days
│   ├── Encryption: KMS
│   └── Content: Security events
├── /aws/rds/{project}
│   ├── Retention: 30 days
│   ├── Encryption: KMS
│   └── Content: RDS audit, error, general, slow query logs
├── aws-waf-logs-{project}-{environment}
│   ├── Retention: 30 days
│   ├── Encryption: None
│   └── Content: WAF blocked/allowed requests
└── /aws/codebuild/{project}
    ├── Retention: 14 days
    ├── Encryption: None
    └── Content: Build logs
```

### CloudWatch Alarms

```
Infrastructure Alarms
├── ALB 5xx Errors
│   ├── Threshold: > 5 in 5 minutes
│   ├── Action: SNS notification
│   └── Severity: High
├── ECS CPU High
│   ├── Threshold: > 80% for 10 minutes
│   ├── Action: SNS notification + Auto-scale
│   └── Severity: Medium
├── ECS Memory High
│   ├── Threshold: > 80% for 10 minutes
│   ├── Action: SNS notification + Auto-scale
│   └── Severity: Medium
├── RDS Connections High
│   ├── Threshold: > 90 connections
│   ├── Action: SNS notification
│   └── Severity: Medium
├── WAF Blocked Requests
│   ├── Threshold: > 100 in 5 minutes
│   ├── Action: SNS notification
│   └── Severity: High
└── Estimated Charges
    ├── Threshold: > $50/day
    ├── Action: SNS notification
    └── Severity: Medium
```

### SNS Topics

```
Alert Topic: {project}-{environment}-alerts
├── Subscriptions
│   └── Email: {alert_email_address}
├── Publishers
│   ├── CloudWatch Alarms
│   ├── AWS Budgets
│   └── Cost Anomaly Detection
└── Protocol: Email
```

### Metrics Dashboard

```
CloudWatch Dashboard: {project}-dashboard
├── Network Traffic (EC2 NetworkIn/Out)
├── ECS Metrics
│   ├── CPU Utilization
│   ├── Memory Utilization
│   └── Running Task Count
├── ALB Metrics
│   ├── Request Count
│   ├── Target Response Time
│   ├── Healthy/Unhealthy Host Count
│   └── HTTP 4xx/5xx Errors
├── RDS Metrics
│   ├── CPU Utilization
│   ├── Database Connections
│   ├── Read/Write IOPS
│   └── Replication Lag
└── Cost Metrics
    └── Estimated Charges
```


---

## Cost Analysis

### Monthly Cost Breakdown (Detailed)

#### Compute Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **ECS Fargate** | | | | |
| vCPU | 0.25 vCPU × $0.04048/hr | $0.01012/hr | 730 hrs × 2 tasks | $14.78 |
| Memory | 0.5 GB × $0.004445/hr | $0.00222/hr | 730 hrs × 2 tasks | $3.24 |
| **Subtotal** | | | | **$18.02** |

#### Database Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **RDS Aurora MySQL** | | | | |
| Writer Instance | db.t4g.medium | $0.082/hr | 730 hrs | $59.86 |
| Reader Instance | db.t4g.medium | $0.082/hr | 730 hrs | $59.86 |
| Storage | Aurora Storage | $0.10/GB-month | 20 GB | $2.00 |
| Backup Storage | S3 Standard | $0.023/GB-month | 10 GB | $0.23 |
| I/O Operations | 1M I/O requests | $0.20/1M | 5M | $1.00 |
| **RDS Proxy** | | | | |
| Proxy Instance | 2 vCPU equivalent | $0.015/hr | 730 hrs | $10.95 |
| **Subtotal** | | | | **$133.90** |

#### Networking Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **Application Load Balancer** | | | | |
| ALB Hours | | $0.0225/hr | 730 hrs | $16.43 |
| LCU Hours | ~5 LCUs average | $0.008/LCU-hr | 730 hrs × 5 | $29.20 |
| **NAT Gateway** | | | | |
| NAT Gateway Hours | 2 gateways | $0.045/hr | 730 hrs × 2 | $65.70 |
| Data Processing | | $0.045/GB | 100 GB | $4.50 |
| **VPC Endpoints** | | | | |
| Interface Endpoints | 4 endpoints | $0.01/hr | 730 hrs × 4 | $29.20 |
| Data Processing | | $0.01/GB | 50 GB | $0.50 |
| **Subtotal** | | | | **$145.53** |

#### Storage Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **S3 Storage** | | | | |
| ALB Logs | Standard | $0.023/GB | 50 GB | $1.15 |
| CodePipeline Artifacts | Standard | $0.023/GB | 10 GB | $0.23 |
| **ECR Storage** | | | | |
| Container Images | | $0.10/GB | 5 GB | $0.50 |
| **Subtotal** | | | | **$1.88** |

#### Security & Management Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **AWS WAF** | | | | |
| Web ACL | 1 ACL | $5.00/month | 1 | $5.00 |
| Rules | 3 rules | $1.00/rule | 3 | $3.00 |
| Requests | | $0.60/1M | 10M | $6.00 |
| **Secrets Manager** | | | | |
| Secrets | 3 secrets | $0.40/secret | 3 | $1.20 |
| API Calls | | $0.05/10K | 100K | $0.50 |
| **KMS** | | | | |
| Customer Keys | 2 keys | $1.00/key | 2 | $2.00 |
| API Requests | | $0.03/10K | 50K | $0.15 |
| **Subtotal** | | | | **$17.85** |

#### Monitoring & Logging Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **CloudWatch** | | | | |
| Log Ingestion | | $0.50/GB | 20 GB | $10.00 |
| Log Storage | | $0.03/GB | 50 GB | $1.50 |
| Metrics | Custom metrics | $0.30/metric | 20 | $6.00 |
| Alarms | | $0.10/alarm | 10 | $1.00 |
| Dashboard | 1 dashboard | $3.00/month | 1 | $3.00 |
| **SNS** | | | | |
| Email Notifications | | $0.00 | 1000 | $0.00 |
| **Cost Explorer** | | | | |
| API Calls | | $0.01/request | 100 | $1.00 |
| **Subtotal** | | | | **$22.50** |

#### CI/CD Services

| Service | Configuration | Unit Cost | Quantity | Monthly Cost |
|---------|--------------|-----------|----------|--------------|
| **CodePipeline** | | | | |
| Active Pipeline | 1 pipeline | $1.00/month | 1 | $1.00 |
| **CodeBuild** | | | | |
| Build Minutes | General1.Medium | $0.005/min | 200 mins | $1.00 |
| **Subtotal** | | | | **$2.00** |

### Total Monthly Cost Summary

| Category | Monthly Cost | Percentage |
|----------|--------------|------------|
| Compute (ECS) | $18.02 | 5.3% |
| Database (RDS + Proxy) | $133.90 | 39.3% |
| Networking (ALB, NAT, VPC) | $145.53 | 42.7% |
| Storage (S3, ECR) | $1.88 | 0.6% |
| Security & Management | $17.85 | 5.2% |
| Monitoring & Logging | $22.50 | 6.6% |
| CI/CD | $2.00 | 0.6% |
| **TOTAL** | **$341.68** | **100%** |

### Cost Optimization Opportunities

#### Immediate Savings (0-1 month)

| Optimization | Current Cost | Optimized Cost | Monthly Savings | Implementation |
|--------------|--------------|----------------|-----------------|----------------|
| Scheduled ECS Scaling | $18.02 | $12.61 | $5.41 (30%) | ✅ Implemented |
| S3 Lifecycle (ALB Logs) | $1.15 | $0.58 | $0.57 (50%) | ✅ Implemented |
| Single NAT (Dev Only) | $70.20 | $37.35 | $32.85 (47%) | Recommended for Dev |
| **Subtotal** | | | **$38.83** | |

#### Short-term Savings (1-3 months)

| Optimization | Current Cost | Optimized Cost | Monthly Savings | Implementation |
|--------------|--------------|----------------|-----------------|----------------|
| Fargate Spot (70% tasks) | $18.02 | $10.81 | $7.21 (40%) | Recommended |
| Right-size RDS | $119.72 | $95.78 | $23.94 (20%) | Requires analysis |
| Reduce Log Retention | $11.50 | $8.05 | $3.45 (30%) | Recommended |
| **Subtotal** | | | **$34.60** | |

#### Long-term Savings (3-12 months)

| Optimization | Current Cost | Optimized Cost | Monthly Savings | Implementation |
|--------------|--------------|----------------|-----------------|----------------|
| RDS Reserved (1-year) | $119.72 | $83.80 | $35.92 (30%) | Recommended |
| Savings Plan (Compute) | $18.02 | $12.61 | $5.41 (30%) | Recommended |
| Aurora Serverless v2 | $119.72 | $71.83 | $47.89 (40%) | Evaluate workload |
| **Subtotal** | | | **$89.22** | |

### Total Potential Savings

| Timeframe | Monthly Savings | Annual Savings |
|-----------|-----------------|----------------|
| Immediate | $38.83 | $465.96 |
| Short-term | $34.60 | $415.20 |
| Long-term | $89.22 | $1,070.64 |
| **Total Potential** | **$162.65** | **$1,951.80** |

### Cost by Environment (Estimated)

| Environment | Configuration | Monthly Cost |
|-------------|--------------|--------------|
| **Development** | | |
| - ECS: 1 task (scaled down) | | $9.01 |
| - RDS: 1 instance (stopped off-hours) | | $40.00 |
| - Networking: Single NAT (cost optimized) | | $80.00 |
| - Other services | | $30.00 |
| **Dev Total** | | **$159.01** |
| | | |
| **Staging** | | |
| - ECS: 2 tasks | | $18.02 |
| - RDS: 2 instances | | $119.72 |
| - Networking: Multi-AZ (2 NAT Gateways) | | $145.53 |
| - Other services | | $58.41 |
| **Staging Total** | | **$341.68** |
| | | |
| **Production** | | |
| - ECS: 4 tasks (higher capacity) | | $36.04 |
| - RDS: 3 instances (writer + 2 readers) | | $179.58 |
| - Networking: Multi-AZ (2 NAT Gateways) | | $182.88 |
| - Other services | | $80.00 |
| **Production Total** | | **$478.50** |

---

## Resource Inventory

### Complete Resource List

#### Network Resources (VPC Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| VPC | {project}-{env}-vpc | 10.0.0.0/16 | Main network |
| Internet Gateway | {project}-{env}-igw | Attached to VPC | Internet access |
| Public Subnet 1 | {project}-public-subnet-1 | 10.0.0.0/24, AZ-1 | ALB, NAT 1 |
| Public Subnet 2 | {project}-public-subnet-2 | 10.0.1.0/24, AZ-2 | ALB, NAT 2 |
| Private Subnet 1 | {project}-private-subnet-1 | 10.0.2.0/24, AZ-1 | ECS, RDS |
| Private Subnet 2 | {project}-private-subnet-2 | 10.0.3.0/24, AZ-2 | ECS, RDS |
| NAT Gateway 1 | {project}-nat-gateway-1 | Public Subnet 1 | Outbound AZ-1 |
| NAT Gateway 2 | {project}-nat-gateway-2 | Public Subnet 2 | Outbound AZ-2 |
| Elastic IP 1 | {project}-nat-eip-1 | Associated with NAT 1 | Static IP AZ-1 |
| Elastic IP 2 | {project}-nat-eip-2 | Associated with NAT 2 | Static IP AZ-2 |
| Public Route Table | {project}-public-rt | IGW route | Public routing |
| Private Route Table 1 | {project}-private-rt-1 | NAT 1 route | Private routing AZ-1 |
| Private Route Table 2 | {project}-private-rt-2 | NAT 2 route | Private routing AZ-2 |

#### Security Resources (Security Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| Web Security Group | {project}-{env}-web-sg | Ports 80, 443 | ALB access |
| App Security Group | {project}-{env}-app-sg | Port 80 from ALB | ECS tasks |
| Database Security Group | {project}-{env}-db-sg | Port 3306 from App | RDS access |
| VPC Endpoint Security Group | {project}-{env}-vpc-endpoint-sg | Port 443 from App | AWS services |
| Public NACL | {project}-public-nacl | Allow all | Public subnet |
| Private NACL | {project}-private-nacl | Allow all | Private subnet |

#### Compute Resources (ECS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| ECS Cluster | {project}-{env}-cluster | Fargate | Container orchestration |
| ECS Task Definition | {project}-{env}-app-task | 0.25 vCPU, 512 MB | Container spec |
| ECS Service | {project}-{env}-app-svc | 1-4 tasks | Running containers |
| Application Load Balancer | {project}-{env}-alb | Internet-facing | Load balancing |
| Target Group | {project}-{env}-tg | HTTP:80 | ECS targets |
| ALB Listener HTTP | Port 80 | Forward to TG | HTTP traffic |
| ALB Listener HTTPS | Port 443 (optional) | Forward to TG | HTTPS traffic |
| Auto Scaling Target | ECS service | 1-4 capacity | Scaling config |
| Auto Scaling Policy CPU | CPU-based | 70% target | CPU scaling |
| Auto Scaling Policy Memory | Memory-based | 80% target | Memory scaling |
| Auto Scaling Policy ALB | Request-based | 1000 req/target | Traffic scaling |
| Scheduled Action Scale Up | 8 AM Mon-Fri | Min=1, Max=4 | Business hours |
| Scheduled Action Scale Down | 6 PM Mon-Fri | Min=1, Max=4 | After hours |

#### IAM Resources (ECS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| ECS Task Execution Role | {project}-{env}-ecsTaskExecutionRole | AWS managed policies | ECR, CloudWatch |
| ECS Task Role | {project}-{env}-ecsTaskRole | Custom policy | App permissions |
| Task Role Policy | {project}-{env}-ecs-task-policy | Secrets, KMS, S3 | Application access |

#### Storage Resources (ECS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| S3 Bucket (ALB Logs) | {project}-{env}-alb-logs-{account} | Encrypted, lifecycle | Access logs |
| S3 Bucket Policy | ALB logs policy | ELB service account | Log delivery |

#### Database Resources (RDS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| RDS Cluster | {project}-{env}-aurora-cluster | Aurora MySQL 8.0 | Database cluster |
| RDS Instance (Writer) | {project}-{env}-aurora-instance-1 | db.t4g.medium | Write operations |
| RDS Instance (Reader) | {project}-{env}-aurora-instance-2 | db.t4g.medium | Read operations |
| DB Subnet Group | {project}-{env}-subnet-group | Private subnets | RDS networking |
| RDS Proxy | {project}-{env}-rds-proxy | Connection pooling | Connection mgmt |
| RDS Proxy Target Group | Default | Pool config | Connection settings |
| RDS Proxy Target | Cluster target | Aurora cluster | Proxy target |
| RDS Proxy IAM Role | {project}-{env}-rds-proxy-role | Secrets access | Proxy permissions |

#### Secrets Resources (RDS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| Secret (DB Username) | {project}-{env}-db-username | KMS encrypted | DB username |
| Secret (DB Password) | {project}-{env}-db-password | KMS encrypted, random | DB password |
| Secret Version (Username) | Latest | Static value | Current username |
| Secret Version (Password) | Latest | Auto-generated | Current password |

#### Container Registry (ECR Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| ECR Repository | {project}-{env}-app-repository | Immutable tags | Container images |
| Image Scanning | Enabled | Scan on push | Vulnerability scan |

#### Encryption Resources (KMS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| KMS Key (Main) | {project}-{env}-key | Rotation enabled | Infrastructure |
| KMS Alias (Main) | alias/{project}-{env}-key | Key alias | Easy reference |

#### VPC Endpoints (VPC Endpoints Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| ECR API Endpoint | com.amazonaws.{region}.ecr.api | Interface | ECR API access |
| ECR DKR Endpoint | com.amazonaws.{region}.ecr.dkr | Interface | Docker registry |
| S3 Gateway Endpoint | com.amazonaws.{region}.s3 | Gateway | S3 access |
| CloudWatch Logs Endpoint | com.amazonaws.{region}.logs | Interface | Log delivery |
| Secrets Manager Endpoint | com.amazonaws.{region}.secretsmanager | Interface | Secrets access |

#### Monitoring Resources (CloudWatch Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| Log Group (VPC Flow) | /aws/vpc/flowlogs/{project} | 14 days, KMS | Network logs |
| Log Group (Application) | /aws/application/{project} | 30 days, KMS | App logs |
| Log Group (Security) | /aws/security/{project} | 90 days, KMS | Security logs |
| Log Group (RDS) | /aws/rds/{project} | 30 days, KMS | Database logs |
| Log Group (ECS) | /ecs/{project}-{env}-app-logs | 7 days | Container logs |
| VPC Flow Log | {project}-vpc-flow-logs | All traffic | Network monitoring |
| Flow Log IAM Role | {project}-flow-logs-role | CloudWatch access | Log delivery |
| Alarm (ALB 5xx) | {project}-alb-5xx | > 5 errors | Error monitoring |
| Alarm (ECS CPU) | {project}-ecs-cpu-high | > 80% | CPU monitoring |
| Alarm (ECS Memory) | {project}-ecs-memory-high | > 80% | Memory monitoring |
| Alarm (RDS Connections) | {project}-rds-connections-high | > 90 | Connection monitoring |
| Alarm (WAF Blocked) | {project}-waf-blocked-requests | > 100 | Security monitoring |
| CloudWatch Dashboard | {project}-dashboard | Multiple widgets | Visualization |

#### Notification Resources (SNS Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| SNS Topic | {project}-{env}-alerts | Email subscription | Notifications |
| SNS Subscription | Email | {alert_email} | Alert delivery |

#### WAF Resources (WAF Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| WAF Web ACL | {project}-{env}-waf | Regional | Application firewall |
| WAF Rule (Common) | AWSManagedRulesCommonRuleSet | AWS managed | OWASP protection |
| WAF Rule (Bad Inputs) | AWSManagedRulesKnownBadInputsRuleSet | AWS managed | Malicious patterns |
| WAF Rule (Rate Limit) | RateLimitRule | 2000 req/5min | DDoS protection |
| WAF ACL Association | ALB association | Attached to ALB | Protection |
| WAF Logging Config | CloudWatch Logs | Log destination | Request logging |
| Log Group (WAF) | aws-waf-logs-{project}-{env} | 30 days | WAF logs |

#### CI/CD Resources (CI/CD Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| S3 Bucket (Artifacts) | {project}-codepipeline-artifacts-{random} | KMS encrypted | Pipeline artifacts |
| S3 Bucket Versioning | Enabled | Version control | Artifact history |
| CodePipeline | {project}-ecs-pipeline | 3 stages | CI/CD automation |
| CodePipeline IAM Role | {project}-codepipeline-role | Pipeline permissions | Pipeline execution |
| CodeBuild Project | {project}-docker-build | Docker build | Image building |
| CodeBuild IAM Role | {project}-codebuild-role | Build permissions | Build execution |
| CodeBuild Log Group | /aws/codebuild/{project} | 14 days | Build logs |
| KMS Key (CI/CD) | {project}-{env}-cicd-secrets | Rotation enabled | CI/CD encryption |
| KMS Alias (CI/CD) | alias/{project}-{env}-cicd-secrets | Key alias | Easy reference |
| Secret (GitHub Token) | {project}-{env}-github-token | KMS encrypted | GitHub access |

#### Cost Monitoring Resources (Cost Monitoring Module)

| Resource Type | Name/ID | Configuration | Purpose |
|--------------|---------|---------------|---------|
| AWS Budget | {project}-{env}-monthly-budget | $1000/month | Cost control |
| Budget Notification (80%) | 80% threshold | Email alert | Warning |
| Budget Notification (100%) | 100% threshold | Email alert | Critical |
| Budget Notification (90% Forecast) | 90% forecast | Email alert | Proactive |
| Cost Anomaly Monitor | {project}-{env}-anomaly-monitor | Service-level | Anomaly detection |
| Anomaly Subscription | {project}-{env}-anomaly-subscription | Daily, $100 threshold | Anomaly alerts |
| CloudWatch Alarm (Billing) | {project}-{env}-estimated-charges | > $50/day | Cost monitoring |

### Total Resource Count

| Category | Count |
|----------|-------|
| Network Resources | 13 |
| Security Resources | 6 |
| Compute Resources | 13 |
| IAM Resources | 3 |
| Storage Resources | 2 |
| Database Resources | 7 |
| Secrets Resources | 4 |
| Container Registry | 1 |
| Encryption Resources | 2 |
| VPC Endpoints | 5 |
| Monitoring Resources | 13 |
| Notification Resources | 2 |
| WAF Resources | 7 |
| CI/CD Resources | 11 |
| Cost Monitoring Resources | 7 |
| **TOTAL** | **96** |

---

## Deployment Guide

### Prerequisites

1. AWS Account with appropriate permissions
2. Terraform >= 1.0 installed
3. AWS CLI configured
4. GitHub repository access
5. Email address for alerts

### Deployment Steps

```bash
# 1. Clone repository
git clone <repository-url>
cd provisioning

# 2. Initialize Terraform
terraform init

# 3. Create terraform.tfvars
cat > terraform.tfvars <<EOF
region               = "us-east-1"
project_name         = "pge-infrastructure"
environment          = "dev"
alert_email_address  = "your-email@example.com"
github_token         = "your-github-token"
db_username          = "admin"
monthly_budget_limit = 1000
EOF

# 4. Plan deployment
terraform plan -out=tfplan

# 5. Apply infrastructure
terraform apply tfplan

# 6. Get outputs
terraform output
```

### Post-Deployment Tasks

1. Confirm SNS email subscription
2. Activate cost allocation tags in AWS Console
3. Configure Route53 (if using custom domain)
4. Upload application code to GitHub
5. Trigger first CI/CD pipeline run
6. Verify application accessibility via ALB DNS
7. Review CloudWatch dashboards
8. Test auto-scaling behavior
9. Verify backup and monitoring

---

## Maintenance & Operations

### Daily Tasks
- Review CloudWatch alarms
- Check cost anomalies
- Monitor application logs

### Weekly Tasks
- Review cost reports
- Analyze performance metrics
- Check for security updates
- Review WAF blocked requests

### Monthly Tasks
- Cost optimization review
- Security audit
- Backup verification
- Capacity planning
- Update documentation

---

## Disaster Recovery

### Backup Strategy

| Component | Backup Method | Frequency | Retention |
|-----------|--------------|-----------|-----------|
| RDS Aurora | Automated snapshots | Daily | 7 days |
| RDS Aurora | Manual snapshots | Weekly | 30 days |
| Container Images | ECR versioning | On push | Indefinite |
| Infrastructure | Terraform state | On change | Version controlled |
| Secrets | Secrets Manager | Automatic | 7 days recovery |

### Recovery Procedures

**RDS Recovery**:
```bash
# Restore from snapshot
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier new-cluster \
  --snapshot-identifier snapshot-id
```

**ECS Recovery**:
```bash
# Rollback to previous task definition
aws ecs update-service \
  --cluster cluster-name \
  --service service-name \
  --task-definition previous-task-def
```

### RTO/RPO Targets

| Component | RTO | RPO |
|-----------|-----|-----|
| Application (ECS) | < 5 minutes | 0 (stateless) |
| Database (RDS) | < 15 minutes | < 5 minutes |
| Infrastructure | < 30 minutes | 0 (IaC) |

---

## Conclusion

This architecture provides a production-ready, secure, scalable, and cost-optimized infrastructure for the PGE application with:

- **High Availability**: Multi-AZ deployment
- **Security**: Multiple layers of defense
- **Scalability**: Auto-scaling for compute and database
- **Observability**: Comprehensive monitoring and logging
- **Cost Efficiency**: Optimized resource usage with monitoring
- **Automation**: Full CI/CD pipeline and IaC

**Estimated Monthly Cost**: $341.68
**Potential Savings**: Up to $162.65/month with optimizations
**Total Resources**: 96 AWS resources managed by Terraform
