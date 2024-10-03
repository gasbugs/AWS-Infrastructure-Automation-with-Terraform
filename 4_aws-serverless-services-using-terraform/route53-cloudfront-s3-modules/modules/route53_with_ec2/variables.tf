variable "private_dns_name" {
  description = "Private DNS 도메인 이름"
  type        = string
}

variable "ami_id" {
  description = "EC2 인스턴스에 사용할 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "pub_key_file_path" {
  description = "공개 키 위치 정보"
  type        = string
}

variable "vpc_name" {
  description = "사용할 vpc 이름"
  type        = string
}

variable "vpc_cidr_block" {
  description = "vpc에 사용할 CIDR 블록 (예: 10.0.0.0/16)"
  type        = string
}

variable "public_subnet_cidr" {
  description = "subnet에 사용할 CIDR 블록 (예: 10.0.0.0/24)"
  type        = string
}

variable "subnet_availability_zone" {
  description = "subnet AZ 위치(예: us-east-1a)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "aws_cloudfront_distribution.s3_distribution.domain_name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "aws_cloudfront_distribution.s3_distribution.hosted_zone_id"
  type        = string
}
