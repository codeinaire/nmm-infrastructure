provider "aws" {
  version = "~> 2.0"
  region  = "ap-southeast-2"
}

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
    },
    {
      http_method = "GET"
      authorization = "CUSTOM"
      type = "AWS_PROXY"
      uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.function_name}/invocations"
    },
    {
      http_method = "OPTIONS"
      authorization = "NONE"
      type = "MOCK"
      uri = ""
    }
  ]
  stage_name = "test"
}
