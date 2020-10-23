resource "aws_iam_role" "lambda_role" {
  name = "milan-lambda-healthcheck"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "vpc_policy" {
  name        = "milan-lvpc-policy"
  description = "VPC policy for lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface", 
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
} 
  EOF
}

resource "aws_iam_policy" "lambda_basic_policy" {
  name        = "milan-lbasic-policy"
  description = "Basic policy for lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "milan-ldynamodb-policy"
  description = "dynamodb policy for lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:*",
                "cloudwatch:PutMetricAlarm"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": [
                        "application-autoscaling.amazonaws.com",
                        "dax.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "replication.dynamodb.amazonaws.com",
                        "dax.amazonaws.com",
                        "dynamodb.application-autoscaling.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "sns_policy" {
  name        = "milan-lsns-policy"
  description = "SNS policy for lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sns:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "ses_policy" {
  name        = "milan-lses-policy"
  description = "SES policy for lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:*"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_iam_policy" "ec2_policy" {
  name        = "milan-lec2-policy"
  description = "EC2 policy for lambda"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [{
      "Effect": "Allow",
      "Action": [
         "ec2:DescribeInstances", 
         "ec2:DescribeImages",
         "ec2:DescribeTags", 
         "ec2:DescribeSnapshots"
      ],
      "Resource": "*"
   }
   ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "vpc-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.vpc_policy.arn
}

resource "aws_iam_role_policy_attachment" "lbasic-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic_policy.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "sns-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_policy.arn
}

resource "aws_iam_role_policy_attachment" "ses-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ses_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2-attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}