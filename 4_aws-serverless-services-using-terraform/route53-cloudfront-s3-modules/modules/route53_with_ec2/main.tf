# VPC 생성
resource "aws_vpc" "new_vpc" {
  cidr_block = var.vpc_cidr_block # VPC의 CIDR 블록 지정 (예: 10.0.0.0/16)

  enable_dns_support   = true # VPC 내의 DNS 지원 활성화
  enable_dns_hostnames = true # VPC 내의 DNS 호스트네임 활성화

  tags = {
    Name = "${var.vpc_name}" # VPC의 태그 이름 설정
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.new_vpc.id # 새로 생성한 VPC에 인터넷 게이트웨이 연결

  tags = {
    Name = "${var.vpc_name}-igw" # 인터넷 게이트웨이의 태그 이름 설정
  }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.new_vpc.id           # 서브넷이 속할 VPC ID
  cidr_block              = var.public_subnet_cidr       # 서브넷의 CIDR 블록 (예: 10.0.1.0/24)
  availability_zone       = var.subnet_availability_zone # 사용할 가용 영역 (예: us-west-2a)
  map_public_ip_on_launch = true                         # EC2 인스턴스 생성 시 퍼블릭 IP 자동 할당

  tags = {
    Name = "${var.vpc_name}-public-subnet" # 서브넷의 태그 이름 설정
  }
}

# 라우팅 테이블 생성
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.new_vpc.id # 라우팅 테이블이 속할 VPC ID

  tags = {
    Name = "${var.vpc_name}-public-rt" # 라우팅 테이블의 태그 이름 설정
  }
}

# 인터넷 게이트웨이로의 라우트 추가
resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.public_route_table.id # 라우팅 테이블 ID
  destination_cidr_block = "0.0.0.0/0"                           # 모든 트래픽을 대상으로 하는 경로 추가
  gateway_id             = aws_internet_gateway.igw.id           # 트래픽의 대상은 인터넷 게이트웨이
}

# 라우팅 테이블과 퍼블릭 서브넷 연결
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id           # 라우팅 테이블과 연결할 서브넷 ID
  route_table_id = aws_route_table.public_route_table.id # 연결할 라우팅 테이블 ID
}

# 랜덤한 숫자 생성 (키 페어 이름에 사용)
resource "random_integer" "key_suffix" {
  min = 1000 # 최소 값
  max = 9999 # 최대 값
}

# 키 페어 생성
resource "aws_key_pair" "generated_key_pair" {
  key_name   = "my-key-${random_integer.key_suffix.result}" # 랜덤한 숫자를 포함한 키 페어 이름
  public_key = file(var.pub_key_file_path)                  # 공개 키 파일의 경로 지정 (로컬에 저장된 .pub 파일)
}

# Route 53 Private Hosted Zone 생성 (VPC와 연결된 Private DNS 영역)
resource "aws_route53_zone" "private_dns" {
  name = var.private_dns_name # Private Hosted Zone의 도메인 이름
  vpc {
    vpc_id = aws_vpc.new_vpc.id # Private Hosted Zone을 연결할 VPC ID
  }
  comment = "Private DNS zone for ${var.private_dns_name}" # Hosted Zone에 대한 설명
}

# CloudFront 도메인 이름을 가리키는 A 레코드 생성
resource "aws_route53_record" "alias_record" {
  zone_id = aws_route53_zone.private_dns.zone_id # Route 53 Zone ID
  name    = var.private_dns_name                 # 도메인 이름
  type    = "A"                                  # A 레코드 타입 지정

  alias {
    name                   = var.cloudfront_domain_name    # CloudFront 도메인 이름 지정
    zone_id                = var.cloudfront_hosted_zone_id # CloudFront의 호스팅 Zone ID
    evaluate_target_health = false                         # 타겟의 상태를 평가하지 않음
  }

  # 가중치 라우팅을 위해 고유 식별자 설정
  set_identifier = "cloudfront-record-1"

  weighted_routing_policy {
    weight = 100 # 100%의 트래픽을 이 배포로 라우팅 (레코드를 여러개 구성해서 가중치 분산 가능)
  }
}

# 보안 그룹 생성 (SSH와 DNS 쿼리를 허용)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"                    # 보안 그룹의 이름
  description = "Allow SSH and DNS traffic" # 보안 그룹에 대한 설명
  vpc_id      = aws_vpc.new_vpc.id          # 보안 그룹이 속할 VPC ID

  ingress {
    description = "Allow SSH" # SSH 트래픽 허용
    from_port   = 22          # SSH 포트
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP 대역에서의 SSH 트래픽 허용
  }

  ingress {
    description = "Allow DNS" # DNS 쿼리 허용
    from_port   = 53          # DNS 포트
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP 대역에서의 DNS 트래픽 허용
  }

  egress {
    from_port   = 0 # 아웃바운드 트래픽 허용 (모든 포트 및 프로토콜)
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP 대역에 대한 아웃바운드 허용
  }
}

# EC2 인스턴스 생성 (Private DNS 테스트용)
resource "aws_instance" "dns_test_instance" {
  ami                    = var.ami_id                               # EC2 인스턴스에 사용할 AMI ID
  instance_type          = var.instance_type                        # EC2 인스턴스의 유형
  subnet_id              = aws_subnet.public_subnet.id              # EC2 인스턴스를 생성할 서브넷 ID
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]           # EC2 인스턴스에 적용할 보안 그룹
  key_name               = aws_key_pair.generated_key_pair.key_name # 생성한 키 페어 이름 사용

  tags = {
    Name = "PrivateDNS-Test-Instance" # 인스턴스의 태그 이름 설정
  }
}
