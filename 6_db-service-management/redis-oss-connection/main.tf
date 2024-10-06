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

# DynamoDB Module
module "dynamodb" {
  source               = "./modules/dynamodb"
  table_name           = var.dynamodb_table_name
  hash_key             = var.dynamodb_hash_key
  hash_key_type        = var.dynamodb_hash_key_type
  range_key            = var.dynamodb_range_key
  range_key_type       = var.dynamodb_range_key_type
  billing_mode         = var.dynamodb_billing_mode
  read_capacity        = var.dynamodb_read_capacity
  write_capacity       = var.dynamodb_write_capacity
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  private_subnet_cidrs = var.private_subnet_cidrs
  region               = var.aws_region
  project_name         = var.project_name
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

# EC2 Module
module "ec2" {
  source                  = "./modules/ec2"
  vpc_id                  = module.vpc.vpc_id
  subnet_id               = element(module.vpc.public_subnet_ids, 0)
  ami_id                  = var.ec2_ami_id
  instance_type           = var.ec2_instance_type
  public_key_path         = var.ec2_public_key_path
  project_name            = var.project_name
  allowed_ssh_cidr_blocks = var.ec2_allowed_ssh_cidr_blocks
  redis_cidr_blocks       = var.redis_allowed_cidr_blocks
  user_data               = var.ec2_user_data
  ec2_instance_profile    = module.dynamodb.ec2_instance_profile
}
