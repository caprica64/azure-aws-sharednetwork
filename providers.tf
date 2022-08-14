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
  region = "sa-east-1"
}