module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "ec2" {
  source = "./modules/ec2"

  ami_id          = var.ami_id
  instance_type   = var.instance_type
  vpc_id          = module.vpc.vpc_id
  subnet_id       = module.vpc.public_subnets[0]
  instance_name   = var.instance_name
  public_key_path = var.public_key_path
}


resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow database access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.vpc_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.vpc_name}-db-subnet-group"
  }
}


resource "aws_db_instance" "my_rds_instance" {
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql" # egine의 종류 https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = var.db_parameter_group_name
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = var.db_multi_az
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  # 백업 관련 설정
  backup_retention_period = 7             # 백업 보존 기간 (일 단위)
  backup_window           = "02:00-03:00" # 백업 시작 시간 (UTC 기준), maintenance_window와 시간이 겹치지 않도록 주의

  # 모니터링 및 유지관리
  maintenance_window = "sun:05:00-sun:06:00" # 유지보수 시간 소프트웨어 업데이트, 버그 수정, 보안 패치 등

  # 스토리지 및 암호화 설정
  storage_type = "gp2" # 스토리지 유형 (gp2: 범용 SSD, io1: 프로비저닝된 IOPS)

  tags = {
    Name        = "My-RDS-MySQL"
    Environment = var.environment
  }
}

# rds-mysql 에제
/*
resource "aws_db_instance" "my_rds_instance" {
  allocated_storage      = 20                             # RDS 인스턴스의 스토리지 크기 (GiB)
  engine                 = "mysql"                        # RDS 인스턴스의 데이터베이스 엔진 (MySQL)
  engine_version         = "8.0"                          # 데이터베이스 엔진 버전
  instance_class         = "db.t3.micro"                  # 인스턴스 유형 (성능 및 비용 고려)
  db_name                = "mydatabase"                   # 데이터베이스 이름
  username               = "admin"                        # 마스터 사용자 이름
  password               = "password"                     # 마스터 사용자 비밀번호 (보안에 유의)
  parameter_group_name   = "default.mysql8.0"             # 데이터베이스 파라미터 그룹
  skip_final_snapshot    = true                           # 삭제 시 최종 스냅샷 생성 여부 (true이면 생성하지 않음)
  publicly_accessible    = false                          # 퍼블릭 액세스 가능 여부 (false이면 VPC 내에서만 접근 가능)
  multi_az               = true                           # 다중 가용 영역 배포 여부 (고가용성 보장)
  vpc_security_group_ids = [aws_security_group.rds_sg.id] # 적용할 보안 그룹 ID
  db_subnet_group_name   = aws_db_subnet_group.this.name  # db를 배포할 서브넷 그룹 이름


  # 백업 관련 설정
  backup_retention_period = 7             # 백업 보존 기간 (일 단위)
  backup_window           = "02:00-03:00" # 백업 시작 시간 (UTC 기준), maintenance_window와 시간이 겹치지 않도록 주의

  # 모니터링 및 유지관리
  monitoring_interval = 60                    # 강화된 모니터링 간격 (초 단위)
  maintenance_window  = "sun:05:00-sun:06:00" # 유지보수 시간 소프트웨어 업데이트, 버그 수정, 보안 패치 등

  # 스토리지 및 암호화 설정
  storage_type      = "gp2"                                                    # 스토리지 유형 (gp2: 범용 SSD, io1: 프로비저닝된 IOPS)
  storage_encrypted = true                                                     # 스토리지 암호화 여부 (true로 설정 시 암호화 활성화)
  # kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/your-kms-key-id" # KMS 키 지정 (선택 사항)


  tags = {
    Name        = "My-RDS-MySQL"
    Environment = "Production"
  }
}
*/

# 읽기 복제본 인스턴스
# 대부분의 설정(엔진, 스토리지, 서브넷, 보안 그룹 등)은 Primary로 부터 가져옵니다. 
resource "aws_db_instance" "read_replica" {
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  publicly_accessible = false
  skip_final_snapshot = true

  replicate_source_db = aws_db_instance.my_rds_instance.id # 원본 인스턴스를 복제

  tags = {
    Name        = "My-RDS-Read-Replica"
    Environment = "Production"
  }
}
