provider "aws" {
  version = "~> 2.0"
  region  = "ap-southeast-2"
}

# ! ___ S3 BUCKET ___ ! #
resource "aws_s3_bucket" "nmm_app" {
  bucket        = "nmm-app-test"
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "nmm-app"
    Environment = "Test"
  }
}

resource "aws_s3_bucket_public_access_block" "nmm_app" {
  bucket = "${aws_s3_bucket.nmm_app.id}"

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# ! ___ API GATEWAY ___ ! #
module "api_gateway" {
  source = "./api_gateway"

  name = "nmmApp"
  path_part = "nmm-graphql"
  api_gateway_method_settings = [
    {
      http_method = "POST"
      authorization = "CUSTOM"
      type = "AWS_PROXY"
      uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.function_name}/invocations"
      integration_http_method = "POST"
      request_template = ""
    },
    {
      http_method = "GET"
      authorization = "CUSTOM"
      type = "AWS_PROXY"
      uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.function_name}/invocations"
      integration_http_method = "POST"
      request_template = ""
    },
    {
      http_method = "OPTIONS"
      authorization = "NONE"
      type = "MOCK"
      uri = ""
      request_template = {
        statusCode = 200
      }
      integration_http_method = "tset"
    }
  ]
  stage_name = "test"
  lambda_function_names = [module.nmm_graphql_lambda.function_name]
}

module "nmm_graphql_lambda" {
  source = "./lambda"

  resource_arn = aws_s3_bucket.nmm_app.arn
  policy_role_name = "s3Write"
  function_name = "graphqlTest"
}
