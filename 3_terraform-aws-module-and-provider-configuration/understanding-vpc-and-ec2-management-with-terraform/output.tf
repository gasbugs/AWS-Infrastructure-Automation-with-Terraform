output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.my_vpc.id
}

output "public_subnet_id" {
  description = "ID of the created public subnet"
  value       = aws_subnet.public_subnet.id
}

output "internet_gateway_id" {
  description = "ID of the created Internet Gateway"
  value       = aws_internet_gateway.my_igw.id
}

output "route_table_id" {
  description = "ID of the created Route Table"
  value       = aws_route_table.public_route_table.id
}

output "security_group_id" {
  description = "ID of the created Security Group"
  value       = aws_security_group.my_sg.id
}

output "ec2_instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.my_ec2.id
}

output "ec2_instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.my_ec2.public_ip
}
