# !___ API GATEWAY COMMON ___ #
resource "aws_api_gateway_rest_api" "nmm_app" {
  name        = var.name
  description = "An api gateway to access my nmm app"
}

resource "aws_api_gateway_resource" "nmm_app" {
  rest_api_id = aws_api_gateway_rest_api.nmm_app.id
  parent_id   = aws_api_gateway_rest_api.nmm_app.root_resource_id
  path_part   = var.path_part
}

resource "aws_api_gateway_deployment" "nmm_app" {
  depends_on = [
    "aws_api_gateway_integration.nmm_app",
    "aws_api_gateway_integration.nmm_app_options"
  ]
  rest_api_id = aws_api_gateway_rest_api.nmm_app.id
  stage_name  = var.stage_name
}

resource "aws_lambda_permission" "nmm_app" {
  for_each = toset(var.lambda_function_names)
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.nmm_app.execution_arn}/*/*"
}

# ! ___ POST, & GET METHODS & INTEGRATIONS ___ ! #

resource "aws_api_gateway_method" "nmm_app" {
  count      = length(var.api_gateway_method_settings)
  rest_api_id   = aws_api_gateway_rest_api.nmm_app.id
  resource_id   = aws_api_gateway_resource.nmm_app.id
  http_method   = lookup(var.api_gateway_method_settings[count.index], "http_method")
  authorization = lookup(var.api_gateway_method_settings[count.index], "authorization")
  authorizer_id = aws_api_gateway_authorizer.nmm_app.id


  # TODO -maybe remove later
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "nmm_app" {
  count      = length(var.api_gateway_method_settings)
  rest_api_id             = aws_api_gateway_rest_api.nmm_app.id
  resource_id             = aws_api_gateway_resource.nmm_app.id
  http_method             = aws_api_gateway_method.nmm_app[count.index].http_method
  type                    = lookup(var.api_gateway_method_settings[count.index], "type")
  uri                     = lookup(var.api_gateway_method_settings[count.index], "uri")
  integration_http_method = "POST"
}

# ! ___ OPTIONS INTEGRATIONS/METHOD RESPONSE ___ ! #
resource "aws_api_gateway_method" "nmm_app_options" {
  rest_api_id   = aws_api_gateway_rest_api.nmm_app.id
  resource_id   = aws_api_gateway_resource.nmm_app.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "nmm_app_options" {
  rest_api_id             = aws_api_gateway_rest_api.nmm_app.id
  resource_id             = aws_api_gateway_resource.nmm_app.id
  http_method             = aws_api_gateway_method.nmm_app_options.http_method
  type                    = "MOCK"

  # request_templates = { statusCode = 200 }
}

resource "aws_api_gateway_method_response" "nmm_app_options" {
  rest_api_id = aws_api_gateway_rest_api.nmm_app.id
  resource_id = aws_api_gateway_resource.nmm_app.id
  http_method = aws_api_gateway_method.nmm_app_options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Origin" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Credentials" = false
  }

  # response_models = {
  #   application/json = "Empty"
  # }
}

resource "aws_api_gateway_integration_response" "nmm_app_options" {
  rest_api_id = aws_api_gateway_rest_api.nmm_app.id
  resource_id = aws_api_gateway_resource.nmm_app.id
  http_method = aws_api_gateway_method.nmm_app_options.http_method
  status_code = aws_api_gateway_method_response.nmm_app_options.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,Access-Control-Allow-Origin,apollographql-client-name,apollographql-client-version'"
    # TODO - Shouldn't use a wildcard value for Allow-Origin
    "method.response.header.Access-Control-Allow-Origin" = "'http://localhost:3000'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  # FIX https://github.com/hashicorp/terraform/issues/7486#issuecomment-257091992
  depends_on = [
    "aws_api_gateway_integration.nmm_app_options"
  ]
}

# ! ___ CUSTOM AUTHORIZER ___ #
resource "aws_api_gateway_authorizer" "nmm_app" {
  name                   = "NmmAppCustomAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.nmm_app.id
  authorizer_uri         = aws_lambda_function.nmm_app.invoke_arn
  authorizer_credentials = aws_iam_role.nmm_app.arn
  identity_validation_expression = "^Bearer [-0-9a-zA-z\\.]*$"
  authorizer_result_ttl_in_seconds = "3600"
}

resource "aws_iam_role_policy_attachment" "nmm_app" {
  role       = aws_iam_role.nmm_app.name
  policy_arn = aws_iam_policy.nmm_app.arn
}

resource "aws_iam_role" "nmm_app" {
  name               = "NmmAppCustomAuthorizerRole"
  assume_role_policy = data.aws_iam_policy_document.nmm_app_assume_role.json
}

data "aws_iam_policy_document" "nmm_app_assume_role" {
  version = "2012-10-17"

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "nmm_app" {
  name   = "NmmAppCustomAuthorizerPolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.nmm_app.json
}

data "aws_iam_policy_document" "nmm_app" {
  version = "2012-10-17"

  statement {
    sid = "AccessCloudwatchLogs"
    actions = ["logs:*"]
    effect = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "CustomAuthorizer"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [aws_lambda_function.nmm_app.invoke_arn]
  }
}

data "archive_file" "custom_authorizer_lambda" {
  type = "zip"
  source_dir = "./custom-authorizer/lambda"
  output_path = "custom-authorizer-lambda.zip"
}

resource "aws_lambda_function" "nmm_app" {
  filename = "${data.archive_file.custom_authorizer_lambda.output_path}"
  function_name = "CustomAuthorizer"
  role = aws_iam_role.nmm_app.arn
  handler = "index.handler"
  runtime = "nodejs10.x"
  source_code_hash = "${filebase64sha256("${data.archive_file.custom_authorizer_lambda.output_path}")}"
  publish = true
}