resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = element(var.private_subnet_cidrs, count.index)
  availability_zone       = "${var.aws_region}${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = "${var.aws_region}${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

# Elastic IP 생성
resource "aws_eip" "nat_gw_eip" {
  count = length(var.public_subnet_cidrs)

  tags = {
    Name = "${var.project_name}-nat-gw-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat_gw_eip[count.index].id
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gw.*.id, 0)
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}
