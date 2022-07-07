# terraform {
#   required_providers {
# 	aws = {
# 	  source = "hashicorp/aws"
# 	  version = "4.20.1"
# 	}
#   }
# }
# 
# provider "aws" {
#   # Configuration options
#   region = "eu-west-1"
# }

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name   = "Spoke1"
  region = var.region
}

################################################################################
# VPC section
################################################################################

#
## Main VPC
#
resource "aws_vpc" "spoke1" {
  cidr_block            = var.cidr_block
  instance_tenancy      = "default"
  
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
	Name                = var.vpc_name
	Project             = "Azure-AWS"
  }
}

#
## Subnets
#
resource "aws_subnet" "Intra1a" {
  cidr_block = var.intra_subnet_1a_cidr
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.spoke1.id
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
	Name = "Intra Subnet AZ 1a"
  }
}

resource "aws_subnet" "Intra1c" {
  cidr_block = var.intra_subnet_1c_cidr
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.spoke1.id
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
	Name = "Intra Subnet AZ 1c"
  }
}

#
## Route tables
#
resource "aws_route_table" "Intra" {
  vpc_id = aws_vpc.spoke1.id
  
  tags = {
	Name = "Intra Route Table"
  }

  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = "tgw-0195fe21097ebc10d"
  }
  
  route {
    cidr_block = "10.0.0.0/16"
    transit_gateway_id = "tgw-0195fe21097ebc10d"
  }
}

#
## Route tables associations
#
resource "aws_route_table_association" "AssociationForRouteTableIntra0" {
  subnet_id = aws_subnet.Intra1a.id
  route_table_id = aws_route_table.Intra.id
}

resource "aws_route_table_association" "AssociationForRouteTableIntra2" {
  subnet_id = aws_subnet.Intra1c.id
  route_table_id = aws_route_table.Intra.id
}


################################################################################
# VPC Attachment section
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attach-intra" {
  subnet_ids         = [aws_subnet.Intra1a.id, aws_subnet.Intra1c.id]
  transit_gateway_id = "tgw-0195fe21097ebc10d" ##To-Do: store and use this value from Parameter Store
  vpc_id             = aws_vpc.spoke1.id

  appliance_mode_support = "disable"
  dns_support = "enable"
  #ipv6_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
	  Name = "Intra-subnet-attachment"
  }
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

