# Packer 설정 블록
packer {
  # Packer에서 사용할 플러그인을 정의하는 부분
  required_plugins {
    amazon = {
      version = ">= 1.0.0" # Packer에서 사용할 플러그인의 최소 버전 지정
      source  = "github.com/hashicorp/amazon" # 플러그인 소스 위치 (AWS용 공식 HashiCorp 플러그인)
    }
  }
}

# AWS 리전을 정의하는 변수
variable "aws_region" {
  type    = string
  default = "us-east-1" # 기본 리전: us-east-1
}

# 인스턴스 타입을 정의하는 변수
variable "instance_type" {
  type    = string
  default = "t2.micro" # 기본 인스턴스 타입: t2.micro
}

# AWS CLI에서 사용할 프로파일을 정의하는 변수
variable "profile" {
  type    = string
  default = "my-sso" # 기본 프로파일: my-sso
}

# 사용할 AMI ID를 정의하는 변수
variable "source_ami" {
  type    = string
  default = "ami-0ebfd941bbafe70c6" # 기본 AMI ID
}

# 현재 시간에 기반하여 AMI 이름에 사용할 타임스탬프 생성
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") # 현재 시간을 문자열로 가져온 후, 허용되지 않는 문자 제거
}

# 첫 번째 빌더: httpd 설치를 위한 amazon-ebs 소스 정의
source "amazon-ebs" "httpd" {
  profile       = var.profile       # AWS CLI 프로파일 지정
  region        = var.aws_region    # 리전 지정
  instance_type = var.instance_type # EC2 인스턴스 타입 지정
  ssh_username  = "ec2-user"        # EC2 인스턴스 SSH 접속용 사용자
  ami_name      = "packer-al2023-httpd-${local.timestamp}" # 생성할 AMI의 이름, 타임스탬프를 포함
  source_ami    = var.source_ami    # 소스로 사용할 AMI ID
}

# 두 번째 빌더: nginx 설치를 위한 amazon-ebs 소스 정의
source "amazon-ebs" "nginx" {
  profile       = var.profile       # AWS CLI 프로파일 지정
  region        = var.aws_region    # 리전 지정
  instance_type = var.instance_type # EC2 인스턴스 타입 지정
  ssh_username  = "ec2-user"        # EC2 인스턴스 SSH 접속용 사용자
  ami_name      = "packer-al2023-nginx-${local.timestamp}" # 생성할 AMI의 이름, 타임스탬프를 포함
  source_ami    = var.source_ami    # 소스로 사용할 AMI ID
}

# httpd 설치를 위한 빌드 블록
build {
  sources = ["source.amazon-ebs.httpd"]

  # 쉘 프로비저너를 통해 인스턴스에 httpd 설치
  provisioner "shell" {
    inline = [
      "sudo yum update -y",                # 인스턴스 패키지 업데이트
      "sudo yum install httpd -y",         # Apache 웹 서버(httpd) 설치
      "sudo systemctl enable httpd --now"  # Apache 웹 서버 서비스 활성화 및 즉시 시작
    ]
  }
}

# nginx 설치를 위한 빌드 블록
build {
  sources = ["source.amazon-ebs.nginx"]

  # 쉘 프로비저너를 통해 인스턴스에 nginx 설치
  provisioner "shell" {
    inline = [
      "sudo yum update -y",                # 인스턴스 패키지 업데이트
      "sudo yum install nginx -y",         # NGINX 웹 서버 설치
      "sudo systemctl enable nginx --now"  # NGINX 웹 서버 서비스 활성화 및 즉시 시작
    ]
  }
}
