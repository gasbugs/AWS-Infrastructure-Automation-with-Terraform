# variables.tf

# AWS 리전 설정
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# 사용할 AWS CLI 프로필
variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "my-sso"
}

# 배포 환경 설정 (예: dev, staging, prod)
variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# S3 버킷 이름 (Terraform 상태 파일 저장용)
variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store Terraform state"
  type        = string
  default     = "my-terraform-state-bucket-gasbugs"
}

# DynamoDB 테이블 이름 (상태 잠금용)
variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock-gasbugs"
}
