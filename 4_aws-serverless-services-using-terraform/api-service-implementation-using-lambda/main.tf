# main.tf

# Terraform 및 AWS 프로바이더 버전 설정
terraform {
  required_version = ">= 1.9.6" # Terraform 최소 요구 버전
  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS 프로바이더의 소스 지정
      version = "~> 4.67"       # 4.x 버전의 AWS 프로바이더 사용
    }
  }
}

# AWS 프로바이더 설정
provider "aws" {
  region  = var.aws_region  # 리소스를 배포할 AWS 리전
  profile = var.aws_profile # 인증에 사용할 AWS CLI 프로파일
}

# 랜덤한 숫자 생성 (IAM Role과 S3 이름에 사용)
resource "random_integer" "random_suffix" {
  min = 1000 # 최소 값
  max = 9999 # 최대 값
}


##########################################################
# 코드 파일 업로드 
# S3 버킷 생성
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "python-resource-${random_integer.random_suffix.result}" # 고유한 버킷 이름 생성
}

# S3 버킷 소유권 설정
resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id # 소유권을 설정할 버킷
  rule {
    object_ownership = "BucketOwnerPreferred" # 버킷 소유자를 우선하도록 설정
  }
}

# S3 버킷 ACL 설정
resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket] # 소유권 설정 이후에 실행

  bucket = aws_s3_bucket.lambda_bucket.id # ACL을 설정할 버킷
  acl    = "private"                      # 버킷의 액세스 제어 목록을 private으로 설정
}

# ZIP 파일 생성 (lambda_function.zip)
data "archive_file" "lambda_hello_world" {
  type = "zip" # ZIP 파일 형식

  source_dir  = "${path.module}/hello-world"     # ZIP으로 압축할 소스 디렉터리
  output_path = "${path.module}/hello-world.zip" # 생성된 ZIP 파일 경로
}

# S3에 Lambda 함수 코드 업로드
resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id # 업로드할 S3 버킷

  key    = "hello-world.zip"                                # 업로드된 ZIP 파일의 키
  source = data.archive_file.lambda_hello_world.output_path # ZIP 파일의 경로

  etag = filemd5(data.archive_file.lambda_hello_world.output_path) # 파일의 MD5 해시값
}

#######################################################
# Lambda 함수 생성
resource "aws_lambda_function" "my_lambda" {
  function_name = "MyLambdaFunction"                     # Lambda 함수 이름
  handler       = "lambda_function.handler"              # Lambda 핸들러 경로
  runtime       = "python3.8"                            # Lambda의 Python 런타임 버전
  role          = aws_iam_role.lambda_execution_role.arn # Lambda 실행 역할의 ARN

  filename         = data.archive_file.lambda_hello_world.output_path         # Lambda 코드 ZIP 파일 경로
  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256 # 코드의 해시값 (변경 감지)

  depends_on = [aws_s3_object.lambda_hello_world] # S3 객체 생성 후 실행
}

# CloudWatch 로그 그룹 생성
resource "aws_cloudwatch_log_group" "hello_world" {
  name              = "/aws/lambda/${aws_lambda_function.my_lambda.function_name}" # 로그 그룹 이름
  retention_in_days = 30                                                           # 로그 보관 기간 설정 (일 기준)
}

# Lambda 실행 역할 생성
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role_${random_integer.random_suffix.result}" # 실행 역할 이름 생성

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com" # Lambda 서비스에 역할 위임
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Lambda에 대한 기본 실행 역할 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name                            # 연결할 IAM 역할 이름
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # Lambda 실행에 필요한 기본 정책
}

##########################################################
# API GW 구성
# API Gateway 생성
resource "aws_apigatewayv2_api" "my_api" {
  name          = "MyApi" # API 이름
  protocol_type = "HTTP"  # 프로토콜 타입 (HTTP)
}

# APIGW와 Lambda 통합 설정
resource "aws_apigatewayv2_integration" "my_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.my_api.id           # API ID
  integration_type       = "AWS_PROXY"                              # 통합 타입 (AWS 프록시)
  integration_uri        = aws_lambda_function.my_lambda.invoke_arn # 통합할 Lambda 함수의 ARN
  payload_format_version = "2.0"                                    # 페이로드 형식 버전
}

# API Gateway 라우트 규칙 설정
resource "aws_apigatewayv2_route" "my_route" {
  api_id    = aws_apigatewayv2_api.my_api.id                                          # API ID
  route_key = "GET /hello"                                                            # HTTP GET 요청 경로
  target    = "integrations/${aws_apigatewayv2_integration.my_lambda_integration.id}" # 통합 대상
}

# API Gateway에 Lambda 실행 권한 부여
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"              # 정책 식별자
  action        = "lambda:InvokeFunction"                     # 허용할 액션
  function_name = aws_lambda_function.my_lambda.function_name # Lambda 함수 이름
  principal     = "apigateway.amazonaws.com"                  # 허용할 주체 (API Gateway)

  source_arn = "${aws_apigatewayv2_api.my_api.execution_arn}/*/*" # API Gateway ARN
}

# API Gateway 스테이지 설정 (dev 환경)
# 경로에 dev를 통해서 요청하도록 구성 가능
# https://vrkiu58szg.execute-api.us-east-1.amazonaws.com/dev/hello
resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.my_api.id # API ID
  name        = "dev"                          # 스테이지 이름 (dev)
  auto_deploy = true                           # 자동 배포 활성화
}

# API Gateway 스테이지 설정 (default 환경)
# 경로에 스테이지를 생략해서 요청하도록 구성 가능
# https://vrkiu58szg.execute-api.us-east-1.amazonaws.com/hello
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.my_api.id # API ID
  name        = "$default"                     # 스테이지 이름 ($default)
  auto_deploy = true                           # 자동 배포 활성화
}
