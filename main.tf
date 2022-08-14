### Spoke 1 infrastructure

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
	CostCenter          = "AoD"
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
    transit_gateway_id = var.tgw_id
  }
  
  route {
    cidr_block = "10.0.0.0/16"
    transit_gateway_id = var.tgw_id
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
  transit_gateway_id = var.tgw_id ##To-Do: Consider a method to store and use this value from Parameter Store
  vpc_id             = aws_vpc.spoke1.id

  appliance_mode_support = "disable"
  dns_support = "enable"
  #ipv6_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
	  Name         = "Intra-subnet-attachment"
	  CostCenter   = "AoD"
  }
}
