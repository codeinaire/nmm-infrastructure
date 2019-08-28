variable "region" {}
variable "account_id" {}
variable "lambda_function_name" {}
variable "cognito_user_pools" {}

resource "aws_api_gateway_rest_api" "example_api" {
  name = "ExampleAPIWithAuthorizer"
  description = "Example Rest Api"
}

resource "aws_api_gateway_resource" "example_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  parent_id = "${aws_api_gateway_rest_api.example_api.root_resource_id}"
  path_part = "messages"
}

resource "aws_api_gateway_authorizer" "example_authorizer" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = "${aws_api_gateway_rest_api.example_api.id}"
  provider_arns = ["${var.cognito_user_pools}"]
}

resource "aws_api_gateway_method" "example_api_method" {
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  resource_id = "${aws_api_gateway_resource.example_api_resource.id}"
  http_method = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.example_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "example_api_method-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  resource_id = "${aws_api_gateway_resource.example_api_resource.id}"
  http_method = "${aws_api_gateway_method.example_api_method.http_method}"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.lambda_function_name}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "secure_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  stage_name = "dev"
}

resource "aws_api_gateway_deployment" "secure_deployment_prod" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  stage_name = "api"
}

output "secure_dev_url" {
  value = "https://${aws_api_gateway_deployment.secure_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.secure_deployment_dev.stage_name}"
}

output "secure_prod_url" {
  value = "https://${aws_api_gateway_deployment.secure_deployment_prod.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.secure_deployment_prod.stage_name}"
}
