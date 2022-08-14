# VPC flow logs

resource "aws_flow_log" "spoke1" {
  iam_role_arn          = aws_iam_role.vpcflow_log_role.arn
  log_destination_type  = "cloud-watch-logs"
  log_destination       = aws_cloudwatch_log_group.vpcflow_log_group.arn
  traffic_type          = "ALL"
  vpc_id                = aws_vpc.spoke1.id
  
  #subnet_id                     # (Optional) Subnet ID to attach to
  #transit_gateway_id            # (Optional) Transit Gateway ID to attach to
  #transit_gateway_attachment_id # (Optional) Transit Gateway Attachment ID to attach to
  max_aggregation_interval = 600  # 600 default, 10 minutes, optional 60 for 1 minute

  tags = {
	  Name                = var.vpc_name
	  Project             = "Azure-AWS"
	  CostCenter          = "AoD"
  }
}


################################################################################
# CloudWatch Log Group
################################################################################
resource "aws_cloudwatch_log_group" "vpcflow_log_group" {
  name                  = "Spoke1_VPC_Flow_Logs"
  retention_in_days     = 7 
  
  tags = {
	  Name                = var.vpc_name
	  Project             = "Azure-AWS"
	  CostCenter          = "AoD"
  }  
  
}

################################################################################
# VPC FlowLog Role and Policy
################################################################################
resource "aws_iam_role" "vpcflow_log_role" {
  name = "VPCFlowLogs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpcflow_log_policy" {
  name = "VPCFlowLogs-Policy"
  role = aws_iam_role.vpcflow_log_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}