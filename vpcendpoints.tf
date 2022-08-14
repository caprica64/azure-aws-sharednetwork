# VPC Endpoints
resource "aws_vpc_endpoint" "private-s3" {
  vpc_id = "${aws_vpc.spoke1.id}"
  service_name = "com.amazonaws.sa-east-1.s3"
  route_table_ids = ["${aws_route_table.Intra.id}"]

  tags = {
	Name                = var.vpc_name
	Project             = "Azure-AWS"
	CostCenter          = "AoD"
  }

  policy = <<POLICY
    {
        "Statement": [
            {
                "Action": "*",
                "Effect": "Allow",
                "Resource": "*",
                "Principal": "*"
            }
        ]
    }
    POLICY
}

resource "aws_vpc_endpoint" "private-dynamodb" {
    vpc_id = "${aws_vpc.spoke1.id}"
    service_name = "com.amazonaws.sa-east-1.dynamodb"
    route_table_ids = ["${aws_route_table.Intra.id}"]

  tags = {
	Name                = var.vpc_name
	Project             = "Azure-AWS"
	CostCenter          = "AoD"
  }

  policy = <<POLICY
    {
        "Statement": [
            {
                "Action": "*",
                "Effect": "Allow",
                "Resource": "*",
                "Principal": "*"
            }
        ]
    }
    POLICY
}