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
resource "aws_vpc" "spoke1" {
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
## subnets
#
resource "aws_subnet" "intra" {
  vpc_id     = aws_vpc.spoke1.id
  count      = 3
  cidr_block = "10.1.${count.index}.0/24"

  tags = {
    Name = "Intra subnet ${count.index}"
    Project = "Azure_AWS"
  }
}


#
## Outbound routes
#
resource "aws_route_table" "main_intra" {
  vpc_id = aws_vpc.spoke1.id

  # Route to Transit network
  route {
    cidr_block = "10.0.0.0/16"
    transit_gateway_id = "tgw-061cba30d883b251d"
  }

  # Route to Azure network(s)
  route {
    cidr_block = "172.31.0.0/16"
    transit_gateway_id = "tgw-061cba30d883b251d"
  }

  # Route to On-Premises
  route {
    cidr_block = "192.168.0.0/24"
    transit_gateway_id = "tgw-061cba30d883b251d"
  }

  # Route to Internet
  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = "tgw-061cba30d883b251d"
  }
  
  tags = {
    Name = "Main Intra RT"
  }
}
#
## Route table associations
#
resource "aws_route_table_association" "main_intra" {
  subnet_id      = aws_subnet.intra.0
  route_table_id = aws_route_table.main_intra.id
}

################################################################################
# Security Groups
################################################################################
#
## Connectivity
#
resource "aws_security_group" "allow_testing_connectivity" {
  name        = "Allow_ec2_tests"
  description = "Allow EC2 instances to test connectivity"
  vpc_id      = aws_vpc.spoke1.id
  
  tags = {
      Name        = "Test-SG"
      Role        = "public"
      Project     = "Azure-AWS"
      Environment = "Dev"
      ManagedBy   = "terraform"
    }
}

resource "aws_security_group_rule" "ssh_in" {
  type               = "ingress"
  from_port          = 22
  to_port            = 22
  protocol           = "tcp"
  cidr_blocks        = ["0.0.0.0/0"]
  security_group_id  = aws_security_group.allow_testing_connectivity.id
  #name               = "SSH inbound"
  description        = "Allow inbound SSH access the EC2 instances"
}

resource "aws_security_group_rule" "icmp_in" {
  type               = "ingress"
  from_port          = 0
  to_port            = 0
  protocol           = "1"
  cidr_blocks        = ["0.0.0.0/0"]
  security_group_id  = aws_security_group.allow_testing_connectivity.id
  #name               = "ICMP inbound"
  description        = "Allow inbound ICMP to the EC2 instances"
}

resource "aws_security_group_rule" "all_out" {
  type               = "egress"
  from_port          = 0
  to_port            = 0
  protocol           = "-1"
  cidr_blocks        = ["0.0.0.0/0"]
  security_group_id  = aws_security_group.allow_testing_connectivity.id
}


## Vars 
## vpc name
## subnet count
## Transit Gateway Id



