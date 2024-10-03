# S3 모듈 호출
module "s3" {
  source = "./modules/s3"

  bucket_name         = var.bucket_name
  environment         = var.environment
  index_document      = var.index_document
  error_document      = var.error_document
  index_document_path = var.index_document_path
  error_document_path = var.error_document_path
}

# CloudFront 모듈 호출
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_name        = var.bucket_name
  bucket_id          = module.s3.bucket_id
  bucket_domain_name = module.s3.bucket_domain_name
  bucket_arn         = module.s3.bucket_arn
  index_document     = var.index_document
}

# route53_with_ec2 모듈 호출
module "route53_with_ec2" {
  source = "./modules/route53_with_ec2"

  cloudfront_domain_name    = module.cloudfront.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.cloudfront.cloudfront_hosted_zone_id

  private_dns_name         = var.private_dns_name
  ami_id                   = var.ami_id
  instance_type            = var.instance_type
  pub_key_file_path        = var.pub_key_file_path
  vpc_name                 = var.vpc_name
  vpc_cidr_block           = var.vpc_cidr_block
  public_subnet_cidr       = var.public_subnet_cidr
  subnet_availability_zone = var.subnet_availability_zone
}
