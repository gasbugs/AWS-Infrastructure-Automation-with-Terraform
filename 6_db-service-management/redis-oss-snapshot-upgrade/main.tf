# VPC Module
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  aws_region           = var.aws_region
  availability_zones   = var.availability_zones
  project_name         = var.project_name
  # elastic_ips          = var.elastic_ips
}

# Redis Module
module "redis" {
  source               = "./modules/redis"
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  project_name         = var.project_name
  allowed_cidr_blocks  = var.redis_allowed_cidr_blocks
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_cache_nodes
  parameter_group_name = var.redis_parameter_group_name
  redis_auth_token     = var.redis_auth_token

}
