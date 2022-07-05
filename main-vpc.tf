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
  }
}





