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