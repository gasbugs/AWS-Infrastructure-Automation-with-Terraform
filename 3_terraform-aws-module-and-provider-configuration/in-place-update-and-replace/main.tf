# main.tf

# Terraform 설정 및 AWS provider 설정
terraform {
  required_version = ">= 1.0.0" // Terraform 버전 1.0.0 이상 사용
}

provider "aws" {
  region  = var.aws_region  // AWS 리전 설정
  profile = var.aws_profile // AWS CLI 프로필 설정
}

# EC2 인스턴스 생성
resource "aws_instance" "my_ec2" {
  ami           = var.ami_id        // 사용할 AMI ID
  instance_type = var.instance_type // 인스턴스 유형 설정 (예: t2.micro)

  tags = {
    Name        = "MyEC2Instance" // 인스턴스의 이름 태그
    Environment = var.environment // 배포 환경 태그 (예: dev, prod)
  }

  lifecycle {
    replace_triggered_by = [aws_key_pair.my_key_pair] # 특정 태그(Environment) 변경 시 Replace 강제
  }
}

// 랜덤한 문자열 생성 (Key Pair 이름 구성에 사용)
resource "random_string" "key_name_suffix" {
  length  = 8
  special = false
  upper   = false
}

// 공개 키 파일 읽기
data "local_file" "public_key" {
  filename = var.public_key_path
}

// 랜덤 문자열을 포함한 Key Pair 이름 생성
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-${random_string.key_name_suffix.result}" // 랜덤한 이름 생성
  public_key = data.local_file.public_key.content

  tags = {
    Name = "MyKeyPair-${random_string.key_name_suffix.result}"
  }
}

