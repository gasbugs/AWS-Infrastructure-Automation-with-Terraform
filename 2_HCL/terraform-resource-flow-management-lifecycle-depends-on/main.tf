// Terraform 설정 및 AWS provider 설정
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "us-east-1" // 배포할 리전 
  profile = "my-sso"
}

// AMI 값을 locals로 지정
locals {
  ami = "ami-0e86e20dae9224db8" // amazon linux 2023로 apply 후 ubuntu로 변경
}

// 리소스 간 의존성 설정
resource "aws_security_group" "example_sg" {
  name = "example-sg"
}

// EC2 인스턴스 생성 전 생명 주기 제어
resource "aws_instance" "example_create_before_destroy_with_dependency" {
  ami           = local.ami
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_security_group.example_sg
  ]
}

// 중요 리소스의 삭제 방지 (S3 이름에 랜덤 숫자 생성)
resource "random_integer" "rand_num" {
  min = 1000
  max = 9999
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "my-important-bucket-${random_integer.rand_num.result}"

  lifecycle {
    prevent_destroy = false
  }
}
