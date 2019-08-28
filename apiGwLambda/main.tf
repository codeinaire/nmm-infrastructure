variable "lambda_policy" {}
variable "lambda_policy_s3" {}
variable "lambda_role" {}
variable "region" {}
variable "account_id" {}



#  ___ LAMBDA FUNCTION 2 ___ #
data "archive_file" "lambda" {
  type = "zip"
  source_dir = "./testLambda"
  output_path = "lambda.zip"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.no_cognito_function.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.no_auth.id}/*/${aws_api_gateway_method.no_auth_method.http_method}${aws_api_gateway_resource.no_auth_resource.path}"
}

resource "aws_lambda_function" "no_cognito_function" {
  filename = "${data.archive_file.lambda.output_path}"
  function_name = "no_cognito_function"
  role = var.lambda_role
  handler = "index.handler"
  runtime = "nodejs10.x"
  source_code_hash = "${filebase64sha256("${data.archive_file.lambda.output_path}")}"
  publish = true
}


#  ___ API GATEWAY ___ #
resource "aws_api_gateway_rest_api" "no_auth" {
  name = "ExampleAPIWith"
  description = "Example Rest Api"
}

resource "aws_api_gateway_resource" "no_auth_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.no_auth.id}"
  parent_id = "${aws_api_gateway_rest_api.no_auth.root_resource_id}"
  path_part = "noauth"
}

resource "aws_api_gateway_method" "no_auth_method" {
  rest_api_id = "${aws_api_gateway_rest_api.no_auth.id}"
  resource_id = "${aws_api_gateway_resource.no_auth_resource.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "no_auth_method-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.no_auth.id}"
  resource_id = "${aws_api_gateway_resource.no_auth_resource.id}"
  http_method = "${aws_api_gateway_method.no_auth_method.http_method}"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.no_cognito_function.function_name}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "example_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.no_auth_method",
    "aws_api_gateway_integration.no_auth_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.no_auth.id}"
  stage_name = "dev"
}

output "no_auth_dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}