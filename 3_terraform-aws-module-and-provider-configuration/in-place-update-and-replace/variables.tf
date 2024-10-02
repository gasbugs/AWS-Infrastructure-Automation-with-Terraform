# variables.tf
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "my-sso"
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "prod" # 기본값을 "dev"로 설정하여 개발 환경을 나타냄
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-0ebfd941bbafe70c6" # Amazon Linux 2023 AMI ID (리전에 맞게 변경하세요)
  # default = "ami-0866a3c8686eaeeba" # Ubuntu Server 24.04 AMI ID 
}

variable "instance_type" {
  description = "The type of instance to create"
  type        = string
  default     = "t2.micro"
}

// 공개 키 파일의 경로
variable "public_key_path" {
  description = "Path to the existing SSH public key"
  type        = string
  default     = "C:/users/isc03/.ssh/my-key-1.pub"
}
