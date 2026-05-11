# IAM role
resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}


resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "${var.prefix}-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ]
      Resource = var.table_arn
    }]
  })
}

resource "aws_iam_role_policy" "kms_policy" {
  name = "${var.prefix}-kms-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "kms:Decrypt"
      Resource = [var.lambda_kms_key_arn, var.dynamodb_kms_key_arn]
    }]
  })
}

# resource "aws_iam_role_policy" "ec2_policy" {
#   name = "${var.prefix}-ec2-network-interface-policy"
#   role = aws_iam_role.lambda_role.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "ec2:DescribeNetworkInterfaces",
#         "ec2:CreateNetworkInterface",
#         "ec2:DescribeSubnets",
#         "ec2:DeleteNetworkInterface",
#         "ec2:AssignPrivateIpAddresses",
#         "ec2:UnassignPrivateIpAddresses"
#       ]
#       Resource = "*"
#     }]
#   })
# }