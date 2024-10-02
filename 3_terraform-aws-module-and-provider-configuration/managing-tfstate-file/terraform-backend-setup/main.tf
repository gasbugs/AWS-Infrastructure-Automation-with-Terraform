// Terraform 설정 및 AWS provider 설정
terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = var.aws_region // 배포할 리전
  profile = var.aws_profile
}

# 기존에 생성된 S3 버킷과 DynamoDB 테이블을 참조해 상태 관리
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "TerraformStateBucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformStateLockTable"
    Environment = var.environment
  }
}
