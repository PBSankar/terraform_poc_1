module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  project_name = var.project_name
  environment  = var.environment
  tags         = var.common_tags
}

module "security" {
  source = "./modules/security"

  vpc_id             = module.vpc.vpc_id
  # vpc_cidr           = var.vpc_cidr
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  project_name       = var.project_name
  environment        = var.environment
  tags               = var.common_tags

  depends_on = [module.vpc]
}

module "ecr" {
  source = "./modules/ecr"

  project_name    = var.project_name
  environment     = var.environment
  repository_name = var.repository_name
  region          = var.region
  image_version   = var.ecr_image_version
  source_image    = var.ecr_source_image
  tags            = var.common_tags

}

module "ecs" {
  source = "./modules/ecs"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  web_security_group_id = module.security.web_security_group_id
  app_security_group_id = module.security.app_security_group_id
  # ecr_repository_url    = module.ecr.repository_url

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  tags         = var.common_tags

  image = var.container_image

  # Task configuration
  task_cpu       = var.ecs_task_cpu
  task_memory    = var.ecs_task_memory
  container_name = var.ecs_container_name

  # Scaling configuration
  desired_count = var.ecs_desired_count
  min_capacity  = var.ecs_min_capacity
  max_capacity  = var.ecs_max_capacity

  depends_on = [module.vpc, module.security, module.ecr]

}

# KMS Module
module "kms" {
  source = "./modules/kms"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.common_tags

}

# RDS Module
module "rds" {
  source = "./modules/rds"

  # vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security.database_security_group_id
  kms_key_arn        = module.kms.kms_key_arn

  instance_class = var.instance_class
  instance_count = var.instance_count
  db_username    = var.db_username

  project_name = var.project_name
  environment  = var.environment

  tags = var.common_tags

  depends_on = [module.vpc, module.security, module.kms]
}

# VPC Endpoints Module
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  vpc_id                         = module.vpc.vpc_id
  region                         = var.region
  private_subnet_ids             = module.vpc.private_subnet_ids
  route_table_ids                = module.vpc.private_route_table_ids
  vpc_endpoint_security_group_id = module.security.vpc_endpoint_security_group_id
  project_name                   = var.project_name
  environment                    = var.environment
  tags                           = var.common_tags

  depends_on = [module.vpc, module.security]
}

# SNS Module # No Permissions to me to execute this module
module "sns" {
  source = "./modules/sns"

  project_name        = var.project_name
  environment         = var.environment
  alert_email_address = var.alert_email_address
  tags                = var.common_tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  vpc_id                 = module.vpc.vpc_id
  region                 = var.region
  project_name           = var.project_name
  environment            = var.environment
  kms_key_arn            = module.kms.kms_key_arn
  alb_arn_suffix         = module.ecs.alb_arn_suffix
  ecs_cluster_name       = module.ecs.cluster_name
  rds_cluster_identifier = module.rds.cluster_identifier
  waf_web_acl_name       = module.waf.web_acl_name
  alarm_actions          = [module.sns.topic_arn]
  tags                   = var.common_tags

  # depends_on = [module.vpc, module.ecs, module.rds, module.sns, module.kms, module.waf]
  depends_on = [ module.vpc, module.ecs, module.rds, module.kms ]
}


# WAF Module # No Permissions to me to execute this module
module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.ecs.alb_arn
  rate_limit   = var.waf_rate_limit
  tags         = var.common_tags

  depends_on = [module.ecs]
}

# Cost Monitoring Module # For Project deployment
module "cost_monitoring" {
  source = "./modules/cost-monitoring"

  project_name         = var.project_name
  environment          = var.environment
  monthly_budget_limit = var.monthly_budget_limit
  daily_cost_threshold = var.daily_cost_threshold
  budget_alert_emails  = [var.alert_email_address]
  cost_anomaly_email   = var.alert_email_address
  alarm_actions        = [module.sns.topic_arn]
  tags                 = var.common_tags

  depends_on = [module.sns]
}


###################################################
# CI/CD Module
module "cicd_infra" {
  source = "./cicd_infra_deploy"
  
  project_name            = var.project_name
  environment             = var.environment
  region                  = var.region
  github_repo_url         = var.github_repo_url
  github_branch           = var.github_branch
  github_token            = var.github_token
  approval_sns_topic_arn  = module.sns.topic_arn
  common_tags             = var.common_tags
}

module "cicd" {
  source = "./cicd_app_deploy"

  project_name    = var.project_name
  environment     = var.environment
  region          = var.region
  repository_name = module.ecr.repository_name
  github_token    = var.github_token
  cluster_name    = module.ecs.cluster_name
  service_name    = module.ecs.service_name
  common_tags     = var.common_tags
  kms_key_arn     = module.kms.kms_key_arn
  

  depends_on = [module.ecr, module.ecs]
}


