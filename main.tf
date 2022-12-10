#AWS VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terra_vpc" #AWS Object Name
  }
}

#AWS Subnet
resource "aws_subnet" "terra_public_subnet" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "terra_public_subnet" #AWS Object Name
  }
}

# AWS Internet Gateway
resource "aws_internet_gateway" "terra_internet_gateway" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_igw"
  }
}

# AWS Route Table
resource "aws_route_table" "terra_public_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_public_rt"
  }
}

# AWS Default Route
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.terra_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terra_internet_gateway.id
}

# Route Table Association
resource "aws_route_table_association" "terra_public_asc" {
  subnet_id      = aws_subnet.terra_public_subnet.id
  route_table_id = aws_route_table.terra_public_rt.id
}