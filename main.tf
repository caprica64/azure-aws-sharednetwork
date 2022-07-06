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
#
## Route tables
#
### Public
resource "aws_route_table" "RouteTablePublic" {
  vpc_id = aws_vpc.VPC.id
  depends_on = [ aws_internet_gateway.Igw ]

  tags = {
	Name = "Public Route Table"
  }

  route {
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.Igw.id
  }
}

resource "aws_route_table_association" "AssociationForRouteTablePublic0" {
  subnet_id = aws_subnet.PublicSubnet1a.id
  route_table_id = aws_route_table.RouteTablePublic.id
}

resource "aws_route_table_association" "AssociationForRouteTablePublic2" {
  subnet_id = aws_subnet.PublicSubnet1c.id
  route_table_id = aws_route_table.RouteTablePublic.id
}

### Private for 1a and 1c AZ
resource "aws_route_table" "RouteTablePrivate1a" {
  vpc_id = aws_vpc.VPC.id
  depends_on = [ aws_nat_gateway.NatGw1a ]

  tags = {
	Name = "Private Route Table 1a"
  }

  route {
	cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.NatGw1a.id
    #transit_gateway_id = "tgw-0a14a39bf577666f8"
  }
}

resource "aws_route_table_association" "AssociationForRouteTablePrivate1a0" {
  subnet_id = aws_subnet.PrivateSubnet1a.id
  route_table_id = aws_route_table.RouteTablePrivate1a.id
}


resource "aws_route_table" "RouteTablePrivate1c" {
  vpc_id = aws_vpc.VPC.id
  depends_on = [ aws_nat_gateway.NatGw1c ]

  tags = {
	Name = "Private Route Table 1c"
  }

  route {
	cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.NatGw1c.id
	#transit_gateway_id = "tgw-0a14a39bf577666f8"
  }
}

resource "aws_route_table_association" "AssociationForRouteTablePrivate1c0" {
  subnet_id = aws_subnet.PrivateSubnet1c.id
  route_table_id = aws_route_table.RouteTablePrivate1c.id
}

#
## Internet Gateway
#
resource "aws_internet_gateway" "Igw" {
  vpc_id = aws_vpc.VPC.id
}
#
## Elastic IP and NAT Gateway for 1a
#
resource "aws_eip" "EipForNatGw1a" {
}

resource "aws_nat_gateway" "NatGw1a" {
  allocation_id = aws_eip.EipForNatGw1a.id
  subnet_id = aws_subnet.PublicSubnet1a.id

  tags = {
	Name = "NAT GW 1a"
  }
}
#
## Elastic IP and NAT Gateway for 1c
#
resource "aws_eip" "EipForNatGw1c" {
}

resource "aws_nat_gateway" "NatGw1c" {
  allocation_id = aws_eip.EipForNatGw1c.id
  subnet_id = aws_subnet.PublicSubnet1c.id

  tags = {
	Name = "NAT GW 1c"
  }
}


################################################################################
# VPC Attachment section
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attach-private" {
  subnet_ids         = [aws_subnet.PrivateSubnet1a.id, aws_subnet.PrivateSubnet1c.id]
  transit_gateway_id = "tgw-0a14a39bf577666f8" ##To-Do: store and use this value from Parameter Store
  vpc_id             = aws_vpc.VPC.id

  appliance_mode_support = "disable"
  dns_support = "enable"
  #ipv6_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
	name = "Private-subnet-attachment"
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
  vpc_id      = aws_vpc.VPC.id
  
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
## Transit Gateway Id <> tgw-0a14a39bf577666f8
