provider "archive" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./test-lambda"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "nmm_graphql_test" {
  filename         = "${data.archive_file.lambda.output_path}"
  function_name    = "nmm-graphql-test"
  role             = "${aws_iam_role.nmm_graphql_test.arn}"
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  source_code_hash = "${filebase64sha256("${data.archive_file.lambda.output_path}")}"
  publish          = true
}

resource "aws_iam_role" "nmm_graphql_test" {
  name               = "s3-read-logs-create"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  version = "2012-10-17"
  # ASSUME ROLE
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# TO REMOVE the s3 access policy from the example api role.
# This means both lambda's don't have anymore access to the S3 bucket.
resource "aws_iam_role_policy_attachment" "s3_policy_to_nmm_graphql_test" {
  role       = aws_iam_role.nmm_graphql_test.name
  policy_arn = aws_iam_policy.lambda_policy_s3_access.arn
}

resource "aws_iam_policy" "lambda_policy_s3_access" {
  name        = "lambda-policy-s3-access"
  description = "A policy attached to the example api role so when it runs it'll be able to access s3 bucket"
  policy      = data.aws_iam_policy_document.s3_list_access_policy.json
}

data "aws_iam_policy_document" "s3_list_access_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:List*",
      "s3:Get*"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.nmm_graphql_test.name
  policy_arn = aws_iam_policy.lambda_logs.arn
}

resource "aws_iam_policy" "lambda_logs" {
  name        = "lambda-logs"
  description = "A policy attached to lambda giving it permission to create logs. In serverless cloudformation config it attaches it to the lambda function"
  policy      = data.aws_iam_policy_document.lambda_logs.json
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    # TODO - make more secure
    # This is not ideal, the serverless cloudformation config was specifying
    # the individual log group
    # arn:${AWS::Partition}:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/lambda/apollo-lambda-dev*:*
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

data "archive_file" "node_modules" {
  type        = "zip"
  source_dir  = "./node_modules"
  output_path = "node_modules.zip"
}

resource "aws_lambda_layer_version" "lambda_node_modules" {
  filename   = "node_modules.zip"
  layer_name = "node_modules"

  compatible_runtimes = ["nodejs10.x"]

  depends_on = ["data.archive_file.node_modules"]
}
