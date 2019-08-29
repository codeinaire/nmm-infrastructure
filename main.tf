provider "aws" {
  region = "ap-southeast-2"
}

# !___ API GATEWAY ___ #
resource "aws_api_gateway_rest_api" "nmm_graphql" {
  name        = "NMM GraphQL"
  description = "A POST and GET method for the Query and Mutations of a GraphQL API"
}

resource "aws_api_gateway_resource" "nmm_graphql_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.nmm_graphql.id}"
  parent_id   = "${aws_api_gateway_rest_api.nmm_graphql.root_resource_id}"
  path_part   = "nmm_graphql"
}

# POST METHOD #
resource "aws_api_gateway_method" "nmm_graphql_post_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.nmm_graphql.id}"
  resource_id   = "${aws_api_gateway_resource.nmm_graphql_resource.id}"
  http_method   = "POST"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nmm_graphql_post_method" {
  rest_api_id             = "${aws_api_gateway_rest_api.nmm_graphql.id}"
  resource_id             = "${aws_api_gateway_resource.nmm_graphql_resource.id}"
  http_method             = "${aws_api_gateway_method.nmm_graphql_post_method.http_method}"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${module.lambda.function_name}/invocations"
  integration_http_method = "POST"
}

# GET METHOD #
resource "aws_api_gateway_method" "nmm_graphql_get_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.nmm_graphql.id}"
  resource_id   = "${aws_api_gateway_resource.nmm_graphql_resource.id}"
  http_method   = "GET"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nmm_graphql_get_method" {
  rest_api_id             = "${aws_api_gateway_rest_api.nmm_graphql.id}"
  resource_id             = "${aws_api_gateway_resource.nmm_graphql_resource.id}"
  http_method             = "${aws_api_gateway_method.nmm_graphql_get_method.http_method}"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${module.lambda.function_name}/invocations"
  # Lambda functions can only be invoke wit hthe POST method - https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html#integration_http_method
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "example_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.nmm_graphql_get_method",
    "aws_api_gateway_method.nmm_graphql_post_method",
    "aws_api_gateway_integration.nmm_graphql_get_method",
    "aws_api_gateway_integration.nmm_graphql_post_method"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.nmm_graphql.id}"
  stage_name  = "dev"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${module.lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # Docs for this: https://www.terraform.io/docs/providers/aws/r/lambda_permission.html#specify-lambda-permissions-for-api-gateway-rest-api
  # Although this doesn't seem to be correct cus I'm getting an error in the console about how the API Gateway resource doesn't have an ANY method associated with it.
  source_arn = "${aws_api_gateway_rest_api.nmm_graphql.execution_arn}/*/*"
}


resource "aws_s3_bucket" "no_meat_may_test_bucket" {
  bucket        = "no-meat-may-test-bucket"
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "No Meat May Bucket"
    Environment = "Test"
  }
}

#! |--- MODULES ---|  #
module "lambda" {
  source = "./lambda"

  bucket_name = aws_s3_bucket.no_meat_may_test_bucket.bucket
}

module "cognito" {
  source = "./cognitoModule"
  fb_provider_id = var.fb_provider_id
}

#! |--- OUTPUTS ---|  #

#  ___ USER POOL ___ #
output "user_pool_password_policy" {
  value       = module.cognito.user_pool_password_policy
  description = "The password policy that we don't want people to know about"
  # this will prevent the output being logged into the console
  sensitive = true
}

output "user_pool_endpoint" {
  value = module.cognito.user_pool_endpoint
}

output "user_pool_arn" {
  value = module.cognito.user_pool_arn
}

output "user_pool_id" {
  value = module.cognito.user_pool_id
}

# ___ USER POOL CLIENT ___ #
output "user_pool_client_id" {
  value = module.cognito.user_pool_client_id
}

# ___ IDENTITY POOL ___ #
output "identity_pool_id" {
  value = module.cognito.identity_pool_id
}

#  ___ S3 BUCKET ___ #
output "s3_policy" {
  value = aws_s3_bucket.no_meat_may_test_bucket.policy
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.no_meat_may_test_bucket.arn
}

output "s3_bucket_region_domain_name" {
  value = aws_s3_bucket.no_meat_may_test_bucket.bucket_regional_domain_name
}

output "dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}
