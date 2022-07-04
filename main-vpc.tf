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
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  #name = "Spoke1"
  cidr = "10.1.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  # public_subnets  = ["10.0.16.0/24", "10.0.17.0/24", "10.0.18.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false
  enable_vpn_gateway = false

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.name}-default" }
  
  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.name}-default" }
  
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }
  
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = {
	Terraform = "true"
	Environment = "dev"
	Project = "Azure-AWS"
  }
}

################################################################################
# VPC Attachment section
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_vpc_attach" {
  #subnet_ids         = ["subnet-0bc9336588e459c56", "subnet-068e851f766c528fd",  "subnet-02bba5610d9d14147"] ## Kept as example when using direct indicated subnet Ids
  #subnet_ids         = var.private_tgw_subnet_ids ## kept as example when using resource versus VPC module
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = "tgw-049f907ea0736b595" ##To-Do: store and use this value from Parameter Store
  vpc_id             = module.vpc.vpc_id

  appliance_mode_support = "disable"
  dns_support = "enable"
  #ipv6_support = "enable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    name = "tgw_vpc_attach_tf"
  }
}

################################################################################
# Security Groups
################################################################################
#
## Test
#
resource "aws_security_group" "allow_testing_connectivity" {
  name        = "allow_ec2_tests"
  description = "Allow EC2 instances to test connectivity"
  vpc_id      = module.vpc.vpc_id
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

resource "aws_security_group_rule" "all_out" {
  type               = "ingress"
  from_port          = 0
  to_port            = 0
  protocol           = "-1"
  cidr_blocks        = ["0.0.0.0/0"]
  security_group_id  = aws_security_group.allow_testing_connectivity.id
}
