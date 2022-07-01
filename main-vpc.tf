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
  region = "eu-west-1"
  #region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Spoke1"
  cidr = "10.1.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  # public_subnets  = ["10.0.16.0/24", "10.0.17.0/24", "10.0.18.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
	Terraform = "true"
	Environment = "dev"
	Project = "Azure-AWS"
  }
}

##Workload AWS Account VPC, attach the vpc to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attach" {
  subnet_ids         = ["subnet-0bc9336588e459c56"]
  #subnet_ids         = var.private_tgw_subnet_ids
  transit_gateway_id = "tgw-049f907ea0736b595"
  vpc_id             = vpc

  appliance_mode_support = "disable"
  dns_support = "enable"
  #ipv6_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    name = "tgw_vpc_attach_tf"
  }
}

#Routetable, enable private subnet route destination to TGW
resource "aws_route" "r_tgw" {
  for_each = toset(var.private_subnet_route_tables_ids)

  route_table_id            = each.key
  destination_cidr_block    = var.tgw_destination_cidr_block
  transit_gateway_id        = var.tgw_id
  depends_on                = [aws_ec2_transit_gateway_vpc_attachment.tgw_vpc_attach]
}