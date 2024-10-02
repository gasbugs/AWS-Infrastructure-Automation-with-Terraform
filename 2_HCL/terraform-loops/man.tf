// Terraform 설정 및 AWS provider 설정
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "us-east-1" // 배포할 리전 
  profile = "my-sso"
}

// 예시1 count를 사용한 반복
resource "aws_instance" "example1" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "Example-Instance-${count.index}"
  }
}

// 예시2 for_each를 사용한 반복
resource "aws_instance" "example2" {
  for_each      = toset(["dev", "staging", "prod"])
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "Example-Instance-${each.key}"
  }
}

// 예시3 for 표현식을 사용한 값 생성 
locals {
  name_tags = [for name in var.instance_names : "Name-${name}"]
}

// 예시4 dynamic 블록을 사용한 리소스 생성
resource "aws_security_group" "example" {
  name = "example-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
