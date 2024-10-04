variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "my-sso"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0ebfd941bbafe70c6"
}

variable "instance_type" {
  description = "Instance type for EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP with the EC2 instance"
  type        = bool
  default     = true
}

// 공개 키 파일의 경로
variable "public_key_path" {
  description = "Path to the existing SSH public key"
  type        = string
  default     = "C:/users/isc03/.ssh/my-key.pub"
}
