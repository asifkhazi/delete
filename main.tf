terraform {
  required_version = "1.8.5"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region  = "ap-south-2"
  profile = "default"
}
resource "aws_vpc" "artbdc_vpc" {
  cidr_block          = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support  = true
  tags = {
    Name = "artbdc_vpc"
  }
}
resource "aws_internet_gateway" "artbdc_igw" {
  vpc_id = aws_vpc.artbdc_vpc.id
  tags = {
    Name = "artbdc_igw"
  }
}
resource "aws_subnet" "artbdc_pub_subnets" {
  count             = 2
  vpc_id            = aws_vpc.artbdc_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "subnet-${count.index + 1}"
  }
}
resource "aws_subnet" "artbdc_pri_subnets" {
  count             = 2
  vpc_id            = aws_vpc.artbdc_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = element(data.aws_availability_zones.available.names, count.index + 2)
  tags = {
    Name = "subnet-${count.index + 3}"
  }
}
data "aws_availability_zones" "available" {}
resource "aws_eip" "nat_eip" {
  vpc = true
}
resource "aws_nat_gateway" "artbdc_ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.artbdc_pub_subnets[0].id
  tags = {
    Name = "artbdc_ngw"
  }
}
resource "aws_route_table" "artbdc_public_rt" {
  vpc_id = aws_vpc.artbdc_vpc.id
  route {
    gateway_id = aws_internet_gateway.artbdc_igw.id
    cidr_block = "0.0.0.0/0"
  }
}
resource "aws_route_table" "artbdc_private_rt" {
  vpc_id = aws_vpc.artbdc_vpc.id
  route {
    nat_gateway_id = aws_nat_gateway.artbdc_ngw.id
    cidr_block     = "0.0.0.0/0"
  }
}
resource "aws_route_table_association" "artbdc_pub_rt_ass" {
  count          = length(aws_subnet.artbdc_pub_subnets)
  route_table_id = aws_route_table.artbdc_private_rt.id
  subnet_id      = aws_subnet.artbdc_pub_subnets[count.index].id
}
resource "aws_route_table_association" "artbdc_pri_rt_ass" {
  count          = length(aws_subnet.artbdc_pri_subnets)
  route_table_id = aws_route_table.artbdc_private_rt.id
  subnet_id      = aws_subnet.artbdc_pri_subnets[count.index].id
}