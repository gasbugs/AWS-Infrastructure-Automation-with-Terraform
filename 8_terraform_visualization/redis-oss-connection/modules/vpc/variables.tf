variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for the subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
}

/*
variable "elastic_ips" {
  description = "List of EIP allocation IDs for NAT Gateways"
  type        = list(string)
}
*/
