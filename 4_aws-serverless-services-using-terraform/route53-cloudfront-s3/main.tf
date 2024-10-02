# Terraform 및 AWS 프로바이더 버전 설정
terraform {
  required_version = ">= 1.0.0" # Terraform 최소 요구 버전
  required_providers {
    aws = {
      source  = "hashicorp/aws" # AWS 프로바이더의 소스 지정
      version = "~> 4.0"        # 4.x 버전의 AWS 프로바이더 사용
    }
  }
}

# AWS 프로바이더 설정
provider "aws" {
  region  = var.aws_region  # 리소스를 배포할 AWS 리전
  profile = var.aws_profile # 인증에 사용할 AWS CLI 프로파일
}

# 랜덤한 숫자 생성 (bucket 이름에 사용)
resource "random_integer" "bucket_suffix" {
  min = 1000 # 최소 값
  max = 9999 # 최대 값
}

# S3 버킷 생성
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.bucket_name}-${random_integer.bucket_suffix.result}" # 버킷 이름에 랜덤 숫자 추가

  tags = {
    Name        = var.bucket_name # 태그로 버킷 이름 설정
    Environment = var.environment # 환경에 대한 태그 지정 (예: dev, prod)
  }
}

# S3 버킷의 정적 웹사이트 설정 구성
resource "aws_s3_bucket_website_configuration" "static_site_website" {
  bucket = aws_s3_bucket.static_site.id # 대상 버킷 지정

  index_document {
    suffix = var.index_document # 인덱스 문서 설정 (예: index.html)
  }

  error_document {
    key = var.error_document # 에러 문서 설정 (예: error.html)
  }
}

# S3 버킷에 인덱스 파일 업로드
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_site.id # 대상 버킷 지정
  key          = var.index_document           # 업로드할 오브젝트의 키 (파일명)
  source       = var.index_document_path      # 로컬에서 업로드할 인덱스 파일의 경로
  content_type = "text/html"                  # 파일의 MIME 타입 설정
}

# S3 버킷에 에러 파일 업로드
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.static_site.id # 대상 버킷 지정
  key          = var.error_document           # 업로드할 오브젝트의 키 (파일명)
  source       = var.error_document_path      # 로컬에서 업로드할 에러 파일의 경로
  content_type = "text/html"                  # 파일의 MIME 타입 설정
}

# Route 53 Public Hosted Zone 생성 (Private Zone 제거)
resource "aws_route53_zone" "public_zone" {
  name = var.domain_name # 원하는 도메인 이름 (예: example.com)
  # private_zone = false           # Public Zone으로 설정
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "S3-origin-access-control"
  description                       = "OAC for CloudFront to S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront 배포 구성 (HTTPS 사용 안 함)
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_domain_name # S3 버킷의 정적 웹사이트 엔드포인트
    origin_id                = "S3-${aws_s3_bucket.static_site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id # OAC ID 연결
  }

  enabled             = true
  default_root_object = var.index_document

  # aliases를 제거하여 기본 CloudFront 도메인 사용
  # CloudFront에 도메인 이름(aliases)을 연결하려면 해당 도메인에 대한 유효한 SSL 인증서를 제공해야 하기 때문에 오류 발생
  # aliases = [var.domain_name] # 제거

  # ACM을 생성하기 까다로우므로 기본 CloudFront 인증서 사용
  viewer_certificate {
    cloudfront_default_certificate = true # CloudFront의 기본 인증서 사용
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_site.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all" # HTTPS를 강제하지 않고 HTTP도 허용
    # viewer_protocol_policy =  "redirect-to-https" # HTTP 요청을 HTTPS로 리디렉션
  }

  # viewer_certificate 제거 (HTTP만 사용)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.bucket_name}-cloudfront"
  }

  web_acl_id = aws_wafv2_web_acl.web_acl.arn # WAF 웹 ACL 연결
}

# CloudFront 도메인 이름을 가리키는 A 레코드 생성
resource "aws_route53_record" "alias_record" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# WAF Web ACL 생성
resource "aws_wafv2_web_acl" "web_acl" {
  name        = "${var.bucket_name}-web-acl"
  description = "WAF for CloudFront to protect ${var.domain_name}"
  scope       = "CLOUDFRONT" # CloudFront용 WAF이므로 스코프를 지정

  default_action {
    allow {}
  }

  # 규칙 정의 (여기서는 Managed Rule Group 예시 사용)
  rule {
    name     = "AWS-CommonRules"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.bucket_name}-waf-metric"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.bucket_name}-web-acl-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.bucket_name}-waf"
  }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "PolicyForCloudFrontPrivateContent",
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_site.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.s3_distribution.arn}"
          }
        }
      }
    ]
  })
}

