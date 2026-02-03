module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count

  project_name = var.project_name
  environment  = var.environment
  tags         = var.common_tags

}

module "security" {
  source = "./modules/security"

  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
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
  repository_name = "app-repository"
  region          = var.region
  tags            = var.common_tags

}

module "ecs" {
  source = "./modules/ecs"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  web_security_group_id = module.security.web_security_group_id
  app_security_group_id = module.security.app_security_group_id
  ecr_repository_url    = module.ecr.repository_url

  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  tags         = var.common_tags

  # ARN of the ECS task execution role from the ECR module
  execution_role_arn = module.ecr.ecs_task_execution_role_arn

  # Docker image to deploy
  image = "nginx:latest"

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

  vpc_id             = module.vpc.vpc_id
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

# module "vpc_endpoints" {
#   source = "./modules/vpc_endpoints"

#   vpc_id             = module.vpc.vpc_id
#   region             = var.region
#   private_subnet_ids = module.vpc.private_subnet_ids
#   # route_table_ids                = concat([module.vpc.public_route_table_id], module.vpc.private_route_table_ids)
#   route_table_ids                = module.vpc.private_route_table_ids
#   vpc_endpoint_security_group_id = module.security.vpc_endpoint_security_group_id
#   project_name                   = var.project_name
#   environment                    = var.environment
#   tags = var.common_tags

#   depends_on = [module.vpc, module.security, module.ecs]
# }


# CI/CD Module
module "cicd" {
  source = "./cicd"

  project_name    = var.project_name
  environment     = var.environment
  region          = var.region
  repository_name = module.ecr.repository_name
  github_token    = var.github_token
  cluster_name    = module.ecs.cluster_name
  service_name    = module.ecs.service_name
  common_tags     = var.common_tags

  depends_on = [module.ecr, module.ecs]
}