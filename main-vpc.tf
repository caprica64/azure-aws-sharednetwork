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
  cidr_block = "10.1.${count.index*64}.0/18"

  tags = {
    Name = "Intra subnet ${count.index}"
    Project = "Azure_AWS"
  }
}

################################################################################
# VPC Attachment section
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attach-private" {
  subnet_ids         = [aws_subnet.intra.[index].id]
  transit_gateway_id = "tgw-00feca5e2a38441d9" ##To-Do: store and use this value from Parameter Store
  vpc_id             = aws_vpc.spoke1.id

  appliance_mode_support = "disable"
  dns_support = "enable"
  #ipv6_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
  Name = "Private-subnet-attachment"
  }
}





#
## Outbound routes
#
# resource "aws_route_table" "main_intra" {
#   vpc_id = aws_vpc.spoke1.id
# 
#   # Route to Transit network
#   route {
#     cidr_block = "10.0.0.0/16"
#     transit_gateway_id = "tgw-00feca5e2a38441d9"
#   }

# # Route to Azure network(s)
#   route {
#     cidr_block = "172.31.0.0/16"
#     transit_gateway_id = "tgw-00feca5e2a38441d9"
#   }
# 
#   # Route to On-Premises
#   route {
#     cidr_block = "192.168.0.0/24"
#     transit_gateway_id = "tgw-00feca5e2a38441d9"
#   }
# 
#   # Route to Internet
#   route {
#     cidr_block = "0.0.0.0/0"
#     transit_gateway_id = "tgw-00feca5e2a38441d9"
#   }
  
#   tags = {
#     Name = "Main Intra RT"
#   }
# }
#
## Route table associations
#
# resource "aws_route_table_association" "main_intra0" {
#   subnet_id      = aws_subnet.intra[0].id
#   route_table_id = aws_route_table.main_intra.id
# }
# 
# resource "aws_route_table_association" "main_intra1" {
#   subnet_id      = aws_subnet.intra[1].id
#   route_table_id = aws_route_table.main_intra.id
# }
# 
# resource "aws_route_table_association" "main_intra2" {
#   subnet_id      = aws_subnet.intra[2].id
#   route_table_id = aws_route_table.main_intra.id
# }

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



