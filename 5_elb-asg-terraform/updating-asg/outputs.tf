# VPC ID 출력
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.example.id
}

# 서브넷 ID들 출력
output "subnet_ids" {
  description = "The IDs of the created subnets"
  value       = [aws_subnet.example1.id, aws_subnet.example2.id]
}

# 오토 스케일링 그룹 이름 출력
output "autoscaling_group_name" {
  description = "The name of the Auto Scaling group"
  value       = aws_autoscaling_group.example.name
}

# 애플리케이션 로드 밸런서의 DNS 이름 출력
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.example.dns_name
}
