// Terraform 설정 및 AWS provider 설정
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "us-east-1" // 배포할 리전 
  profile = "my-sso"
}

// 모듈 호출
module "vpc" {
  source     = "./modules/vpc"
  vpc_name   = "my-vpc"
  cidr_block = "10.0.0.0/16"
}
