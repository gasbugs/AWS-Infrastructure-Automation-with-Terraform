# random_integer 리소스: 키 페어 이름에 사용할 랜덤 값 생성
resource "random_integer" "example" {
  min = 1000
  max = 9999
}

# 기존 키 페어 사용
resource "aws_key_pair" "example" {
  key_name   = "example-keypair-${random_integer.example.result}"
  public_key = file(var.pub_key_file_path)
}

# VPC 생성
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

# 서브넷 생성
resource "aws_subnet" "example1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "example-subnet-1"
  }
}

resource "aws_subnet" "example2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "example-subnet-2"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-igw"
  }
}

# 라우팅 테이블 생성 및 연결
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
  tags = {
    Name = "example-rt"
  }
}

resource "aws_route_table_association" "example1" {
  subnet_id      = aws_subnet.example1.id
  route_table_id = aws_route_table.example.id
}

resource "aws_route_table_association" "example2" {
  subnet_id      = aws_subnet.example2.id
  route_table_id = aws_route_table.example.id
}

# ACM 인증서 리소스: 사용자의 인증서를 ACM에 업로드
resource "aws_acm_certificate" "example" {
  private_key      = file(var.private_key_file_path)
  certificate_body = file(var.certificate_body_file_path)
  # certificate_chain = file(var.certificate_chain_file_path)
}

# 로드 밸런서 생성
resource "aws_lb" "example" {
  name                       = "example-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.example1.id, aws_subnet.example2.id]
  security_groups            = [aws_security_group.for_alb.id]
  enable_deletion_protection = false
}

# HTTPS 리스너 설정
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.example.arn

  default_action {
    target_group_arn = aws_lb_target_group.example.arn
    type             = "forward"
  }
}

# HTTP -> HTTPS 리다이렉션 설정 (옵션)
resource "aws_lb_listener" "http_redirect_listener" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 로드 밸런서의 타겟 그룹 생성
resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id
  health_check {
    path     = "/index.html"
    protocol = "HTTP"
  }
}

# 오토 스케일링 그룹 생성 및 타겟 그룹 연결
resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  vpc_zone_identifier = [aws_subnet.example1.id, aws_subnet.example2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  tag {
    key                 = "Name"
    value               = "ASG-Instance"
    propagate_at_launch = true
  }
}

# 오토 스케일링 그룹 인스턴스를 타겟 그룹에 연결
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.name
  lb_target_group_arn    = aws_lb_target_group.example.arn
}

# ALB 보안 그룹에 HTTPS 트래픽 허용 규칙 추가
resource "aws_security_group" "for_alb" {
  name_prefix = "for-alb"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "for-alb"
  }
}


# EC2 보안 그룹에 HTTP 트래픽 허용 규칙 추가
resource "aws_security_group" "for_ec2" {
  name_prefix = "for-ec2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "for-ec2"
  }
}

# Launch Template 생성
resource "aws_launch_template" "example" {
  name_prefix   = "example-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = aws_key_pair.example.key_name

  network_interfaces {
    security_groups = [aws_security_group.for_ec2.id]
  }
}
