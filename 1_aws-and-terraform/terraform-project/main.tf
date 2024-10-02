// Terraform 설정 및 AWS provider 설정
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "us-east-1" // 배포할 리전 
  profile = "my-sso"
}

// 간단한 EC2 인스턴스 리소스 구성
resource "aws_instance" "example" {
  ami           = "ami-0ebfd941bbafe70c6" // 배포할 리전에서 AMI 확인 후 변경 필수 
  instance_type = "t2.micro"
}
