# !___ API GATEWAY COMMON ___ #
resource "aws_api_gateway_rest_api" "nmm_app" {
  name        = var.name
}

resource "aws_api_gateway_resource" "nmm_app_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.nmm_app.id}"
  parent_id   = "${aws_api_gateway_rest_api.nmm_app.root_resource_id}"
  path_part   = var.path_part
}

# resource "aws_api_gateway_deployment" "nmm_app" {
#   depends_on = [
#     "aws_api_gateway_integration.nmm_app_get_method",
#     "aws_api_gateway_integration.nmm_app_post_method",
#     "aws_api_gateway_integration.nmm_app_options_method"
#   ]
#   rest_api_id = "${aws_api_gateway_rest_api.nmm_app.id}"
#   stage_name  = var.stage_name
# }

resource "aws_api_gateway_method" "nmm_app" {
  count      = length(var.api_gateway_method_settings)
  rest_api_id   = "${aws_api_gateway_rest_api.nmm_app.id}"
  resource_id   = "${aws_api_gateway_resource.nmm_app_resource.id}"
  http_method   = lookup(var.api_gateway_method_settings[count.index], "http_method")
  authorization = lookup(var.api_gateway_method_settings[count.index], "authorization")
  # authorizer_id = aws_api_gateway_authorizer.nmm_app.id

  # TODO -remove later
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nmm_app" {
  count      = length(var.api_gateway_method_settings)
  rest_api_id             = "${aws_api_gateway_rest_api.nmm_app.id}"
  resource_id             = "${aws_api_gateway_resource.nmm_app_resource.id}"
  http_method             = "${aws_api_gateway_method.nmm_app[count.index].http_method}"
  type                    = lookup(var.api_gateway_method_settings[count.index], "type")
  uri                     = lookup(var.api_gateway_method_settings[count.index], "uri")
  integration_http_method = "POST"
}

# # ! POST METHOD #

# resource "aws_api_gateway_integration" "nmm_app_post_method" {
#   rest_api_id             = "${aws_api_gateway_rest_api.nmm_app.id}"
#   resource_id             = "${aws_api_gateway_resource.nmm_app_resource.id}"
#   http_method             = "${aws_api_gateway_method.nmm_app_post_method.http_method}"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.nmm_app_post.function_name}/invocations"
#   integration_http_method = "POST"
# }

# resource "aws_lambda_permission" "apigw_lambda_post" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = "${aws_lambda_function.nmm_app_post.function_name}"
#   principal     = "apigateway.amazonaws.com"

#   # Docs for this: https://www.terraform.io/docs/providers/aws/r/lambda_permission.html#specify-lambda-permissions-for-api-gateway-rest-api
#   # Although this doesn't seem to be correct cus I'm getting an error in the console about how the API Gateway resource doesn't have an ANY method associated with it.
#   source_arn = "${aws_api_gateway_rest_api.nmm_app.execution_arn}/*/*"
# }

# # ! GET METHOD #

# resource "aws_api_gateway_integration" "nmm_app_get_method" {
#   rest_api_id             = "${aws_api_gateway_rest_api.nmm_app.id}"
#   resource_id             = "${aws_api_gateway_resource.nmm_app_resource.id}"
#   http_method             = "${aws_api_gateway_method.nmm_app_get_method.http_method}"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.nmm_app_get.function_name}/invocations"
#   # Lambda functions can only be invoke wit hthe POST method - https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html#integration_http_method
#   integration_http_method = "POST"
# }

# resource "aws_lambda_permission" "apigw_lambda_get" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = "${aws_lambda_function.nmm_app_get.function_name}"
#   principal     = "apigateway.amazonaws.com"

#   # Docs for this: https://www.terraform.io/docs/providers/aws/r/lambda_permission.html#specify-lambda-permissions-for-api-gateway-rest-api
#   # Although this doesn't seem to be correct cus I'm getting an error in the console about how the API Gateway resource doesn't have an ANY method associated with it.
#   source_arn = "${aws_api_gateway_rest_api.nmm_app.execution_arn}/*/*"
# }

# # ! OPTIONS METHOD #

# resource "aws_api_gateway_integration" "nmm_app_options_method" {
#   rest_api_id             = "${aws_api_gateway_rest_api.nmm_app.id}"
#   resource_id             = "${aws_api_gateway_resource.nmm_app_resource.id}"
#   http_method             = "${aws_api_gateway_method.nmm_app_options_method.http_method}"
#   type                    = "MOCK"
# }

# resource "aws_api_gateway_method_response" "nmm_app_options" {
#   rest_api_id = "${aws_api_gateway_rest_api.nmm_app.id}"
#   resource_id = "${aws_api_gateway_resource.nmm_app_resource.id}"
#   http_method = "${aws_api_gateway_method.nmm_app_options_method.http_method}"
#   status_code = "200"
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = true
#     "method.response.header.Access-Control-Allow-Origin" = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Credentials" = true
#   }
# }


# resource "aws_api_gateway_integration_response" "nmm_app_options" {
#   rest_api_id = "${aws_api_gateway_rest_api.nmm_app.id}"
#   resource_id = "${aws_api_gateway_resource.nmm_app_resource.id}"
#   http_method = "${aws_api_gateway_method.nmm_app_options_method.http_method}"
#   status_code = "${aws_api_gateway_method_response.nmm_app_options.status_code}"
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
#     # TODO - Shouldn't use a wildcard value for Allow-Origin
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
#     "method.response.header.Access-Control-Allow-Methods" = "'POST,GET,OPTIONS'"
#     "method.response.header.Access-Control-Allow-Credentials" = "'true'"
#   }
# }