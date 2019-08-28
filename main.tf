provider "aws" {
  region = "ap-southeast-2"
}

provider "archive" {}


# This is the docs for GROUPS - https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-user-groups.html

# resource "aws_cognito_user_group" "api_gateway_access" {
#   name = "api-gateway-access"
#   user_pool_id = aws_cognito_user_pool.no_meat_may.id
#   precedence = 1
#   role_arn = aws_iam_role.api_gateway_access.arn
# }

# * Probably don't need this
# resource "aws_iam_role" "s3_list_access_role" {
#   name = "s3_list_access_role"
#   # This will grant the role the ability for cognito identity to assume it
#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Federated": "cognito-identity.amazonaws.com"
#       },
#       "Action": "sts:AssumeRoleWithWebIdentity",
#       "Condition": {
#         "StringEquals": {
#           "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.no_meat_may_id_pool.id}"
#         },
#         "ForAnyValue:StringLike": {
#           "cognito-identity.amazonaws.com:amr": "authenticated"
#         }
#       }
#     }
#   ]
# }
# EOF
# }

#  This attaches the lambda s3 policy to the s3_list_access_role
# resource "aws_iam_role_policy" "s3_access" {
#   name   = "s3_access"
#   role   = aws_iam_role.s3_list_access_role.id
#   policy = module.lambda_policy.lambda_policy_s3_json
# }

#  !___ LAMBDA FUNCTION 1 ___ #
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./testLambda"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "example_test_function" {
  filename         = "${data.archive_file.lambda.output_path}"
  function_name    = "example_test_function"
  role             = "${aws_iam_role.example_api_role.arn}"
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  source_code_hash = "${filebase64sha256("${data.archive_file.lambda.output_path}")}"
  publish          = true
}

resource "aws_iam_role" "example_api_role" {
  name               = "example_api_role"
  assume_role_policy = module.lambda_policy.lambda_assume_role_policy
}

# TO REMOVE the s3 access policy from the example api role.
# This means both lambda's don't have anymore access to the S3 bucket.
resource "aws_iam_role_policy_attachment" "s3_policy_to_example_api_role" {
  role       = aws_iam_role.example_api_role.name
  policy_arn = aws_iam_policy.lambda_policy_s3_access.arn
}

resource "aws_iam_policy" "lambda_policy_s3_access" {
  name        = "lambda-policy-s3-access"
  description = "A policy attached to the example api role to so when it runs it'll be able to access s3 bucket"
  policy      = module.lambda_policy.lambda_policy_s3_json
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example_test_function.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.example_api.id}/*/${aws_api_gateway_method.example_api_method.http_method}${aws_api_gateway_resource.example_api_resource.path}"
}

# !___ API GATEWAY ___ #
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "Secure API Gateway"
  description = "Example Rest Api"
}

resource "aws_api_gateway_resource" "example_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.example_api.root_resource_id}"
  path_part   = "messages"
}

# Don't need this for Federate SignIn
# resource "aws_api_gateway_authorizer" "example_authorizer" {
#   name          = "CognitoUserPoolAuthorizer"
#   type          = "COGNITO_USER_POOLS"
#   rest_api_id   = "${aws_api_gateway_rest_api.example_api.id}"
#   provider_arns = ["${module.cognito.user_pool_arn}"]
#   # I'm wondering if this is required if the authorizer has the
#   # APIG access credentials in the ID Pool??
#   # authorizer_credentials
# }

resource "aws_api_gateway_method" "example_api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.example_api.id}"
  resource_id   = "${aws_api_gateway_resource.example_api_resource.id}"
  http_method   = "POST"
  authorization = "AWS_IAM"
  # authorizer_id = aws_api_gateway_authorizer.example_authorizer.id

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "example_api_method-integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.example_api.id}"
  resource_id             = "${aws_api_gateway_resource.example_api_resource.id}"
  http_method             = "${aws_api_gateway_method.example_api_method.http_method}"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.example_test_function.function_name}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "example_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  stage_name  = "dev"
}



# |--- SECURE API GATEWAY MODULE---|  #

# module "secureApiGateway" {
#   source = "./secureApiGateway"

#   lambda_function_name = aws_lambda_function.example_test_function.function_name
#   cognito_user_pools = aws_cognito_user_pool.no_meat_may.arn
  # region           = var.region
  # account_id       = var.account_id

# }

# This will be needed when I'm using the no meat may domain
# resource "aws_cognito_user_pool_domain" "no_meat_may" {
#   domain       = "no-meat-may"
#   user_pool_id = "${aws_cognito_user_pool.no_meat_may.id}"
# }

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
module "lambda_policy" {
  source = "./iamPolicy"

  s3_bucket_name    = aws_s3_bucket.no_meat_may_test_bucket.bucket
}

module "api_lambda_no_auth" {
  source = "./apiGwLambda"

  lambda_policy    = module.lambda_policy.lambda_assume_role_policy
  lambda_policy_s3 = module.lambda_policy.lambda_policy_s3_json
  lambda_role      = aws_iam_role.example_api_role.arn
  region           = var.region
  account_id       = var.account_id
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

# output "secure_dev_url" {
#   value = module.secureApiGateway.secure_dev_url
# }

# output "lambda_role_policy" {
#   value = aws_iam_policy.s3_access.policy
# }

output "dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}

output "no_auth_dev_url" {
  value = module.api_lambda_no_auth.no_auth_dev_url
}
