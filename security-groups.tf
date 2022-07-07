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

