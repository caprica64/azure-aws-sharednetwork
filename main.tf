terraform {
  required_providers {
	aws = {
	  source = "hashicorp/aws"
	  version = "4.20.1"
	}
  }
}

provider "aws" {
  # Configuration options
  region = "eu-west-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name   = "Spoke1"
  region = "eu-west-1"
  #region = var.region
}

################################################################################
# VPC section
################################################################################

#
## Main VPC
#
resource "aws_vpc" "VPC" {
  cidr_block            = "10.1.0.0/16"
  instance_tenancy      = "default"
  
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
	Name                = "Spoke1-VPC"
	Project             = "Azure-AWS"
  }
}

#
## Subnets
#
resource "aws_subnet" "PublicSubnet1a" {
  cidr_block = "10.1.0.0/24"
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
	Name = "Public Subnet AZ 1a"
  }
}

resource "aws_subnet" "PublicSubnet1c" {
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
	Name = "Public Subnet AZ 1c"
  }
}

resource "aws_subnet" "PrivateSubnet1a" {
  cidr_block = "10.1.10.0/24"
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
	Name = "Private Subnet AZ 1a"
  }
}

resource "aws_subnet" "PrivateSubnet1c" {
  cidr_block = "10.1.11.0/24"
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.VPC.id
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
	Name = "Private Subnet AZ 1c"
  }
}