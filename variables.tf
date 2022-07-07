#Region
variable "region" {}

#VPC variables
variable "vpc_name" {}
variable "cidr_block" {}
variable "intra_subnet_1a_cidr" {}
variable "intra_subnet_1c_cidr" {}

#Transit Gateway Id
variable "tgw_id" {}

#Transit destination CIDR block
variable "transit_cidr" {}

