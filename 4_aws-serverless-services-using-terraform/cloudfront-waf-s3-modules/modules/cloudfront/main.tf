# CloudFront의 S3 접근을 위한 Origin Access Control 설정
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "S3-origin-access-control"
  description                       = "OAC for CloudFront to S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront 배포 구성
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = var.bucket_domain_name
    origin_id                = "S3-${var.bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = var.index_document

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # viewer_protocol_policy = "allow-all"
    viewer_protocol_policy = "redirect-to-https"
  }

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

# CloudFront를 위한 S3 버킷 정책 생성 
resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = var.bucket_id

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
        Resource = "${var.bucket_arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.s3_distribution.arn}"
          }
        }
      }
    ]
  })
}

# WAF Web ACL 생성
resource "aws_wafv2_web_acl" "web_acl" {
  name        = "${var.bucket_name}-web-acl"                       # WAF Web ACL 이름 설정
  description = "WAF for CloudFront to protect ${var.bucket_name}" # WAF 설명 추가
  scope       = "CLOUDFRONT"                                       # CloudFront용 WAF이므로 스코프를 지정

  default_action {
    allow {} # 기본적으로 모든 요청 허용
  }

  # 규칙 정의 (여기서는 Managed Rule Group 예시 사용)
  rule {
    name     = "AWS-CommonRules" # 규칙 이름 지정
    priority = 1                 # 규칙 우선순위

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet" # AWS에서 제공하는 관리형 규칙 그룹 사용
        vendor_name = "AWS"                          # 규칙 그룹의 제공자
      }
    }

    # AWS WAF의 규칙에 정의된 동작을 무시하고 지정된 동작을 수행하도록 하는 역할
    override_action {
      none {} # 규칙의 동작을 무시하지 않고, 원래 규칙에 지정된 동작을 수행
      # count {} 규칙이 지정된 동작을 수행하는 대신, 해당 요청을 단순히 카운트
    }

    # visibility_config을 통해 WAF가 어떻게 로그를 수집하고 메트릭을 기록할지 지정
    visibility_config {
      sampled_requests_enabled   = true                            # 샘플 요청 활성화
      cloudwatch_metrics_enabled = true                            # CloudWatch 메트릭 활성화
      metric_name                = "${var.bucket_name}-waf-metric" # CloudWatch 메트릭 이름
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet" # 규칙 이름 지정
    priority = 2                            # 규칙 우선순위

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet" # AWS에서 제공하는 관리형 규칙 그룹 사용
        vendor_name = "AWS"                        # 규칙 그룹의 제공자
      }
    }

    # AWS WAF의 규칙에 정의된 동작을 무시하고 지정된 동작을 수행하도록 하는 역할
    override_action {
      none {} # 규칙의 동작을 무시하지 않고, 원래 규칙에 지정된 동작을 수행
      # count {} 규칙이 지정된 동작을 수행하는 대신, 해당 요청을 단순히 카운트
    }

    # visibility_config을 통해 WAF가 어떻게 로그를 수집하고 메트릭을 기록할지 지정
    visibility_config {
      sampled_requests_enabled   = true                            # 샘플 요청 활성화
      cloudwatch_metrics_enabled = true                            # CloudWatch 메트릭 활성화
      metric_name                = "${var.bucket_name}-waf-metric" # CloudWatch 메트릭 이름
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true                                # CloudWatch 메트릭 활성화
    metric_name                = "${var.bucket_name}-web-acl-metric" # Web ACL 메트릭 이름
    sampled_requests_enabled   = true                                # 샘플 요청 활성화
  }

  tags = {
    Name = "${var.bucket_name}-waf" # WAF Web ACL의 태그 이름 설정
  }
}
