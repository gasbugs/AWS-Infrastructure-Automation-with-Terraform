# 키 페어를 정의
# 1000부터 9999 사이의 랜덤 값을 생성
resource "random_integer" "example" {
  min = 1000
  max = 9999
}

resource "aws_key_pair" "example" {
  key_name   = "example-keypair-${random_integer.example.result}"
  public_key = file(var.pub_key_file_path)
}

# VPC를 정의
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example-vpc"
  }
}

# 서브넷을 정의
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

# 인터넷 게이트웨이를 정의
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-igw"
  }
}

# 라우팅 테이블을 정의하고 서브넷과 인터넷 게이트웨이에 연결
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

# Launch Template을 정의
resource "aws_launch_template" "example" {
  name_prefix   = "example-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = aws_key_pair.example.key_name

  network_interfaces {
    security_groups = [aws_security_group.example.id]
  }
}


# 오토 스케일링 그룹을 정의
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

# 애플리케이션 로드 밸런서를 정의
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.example1.id, aws_subnet.example2.id]
  security_groups    = [aws_security_group.example.id]

  enable_deletion_protection = false # 삭제 방지 옵션
}

# 로드 밸런서의 리스너와 타겟 그룹을 정의
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.example.arn
    type             = "forward"
  }
}

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

# 오토 스케일링 그룹 인스턴스를 타겟 그룹에 연결
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.example.name
  lb_target_group_arn    = aws_lb_target_group.example.arn
}

# HTTP 및 SSH 트래픽을 허용하는 보안 그룹을 정의
resource "aws_security_group" "example" {
  name_prefix = "example-sg"
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
    Name = "example-sg"
  }
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  alarm_actions       = [aws_autoscaling_policy.scale_in_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }
}
