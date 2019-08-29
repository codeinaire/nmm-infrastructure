variable "fb_provider_id" {}

# this part of the aws tute is here - https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-as-user-directory.html
resource "aws_cognito_user_pool" "no_meat_may" {
  # These are grouped according to the pages on the console
  name = "no-meat-may-users"

  # Attributes
  alias_attributes = ["email", "preferred_username"]
  # TODO - Update these when I speak to Ryan about the details he wants for a user
  # schema {
  #   attribute_data_type = "String"
  #   mutable             = true
  #   name                = "nickname"
  #   required            = true
  # }
  # schema {
  #   attribute_data_type = "String"
  #   mutable             = true
  #   name                = "motivation"
  #   # A custom attribute cannot be required
  #   required = false
  # }

  # Policies - we can set the admin to create a user, but that requires a backend auth process
  # look up best practice for password creation
  password_policy {
    minimum_length    = "6"
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  # MFA and verifications
  mfa_configuration        = "OFF"
  auto_verified_attributes = ["email"]

  # Message customizations
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_LINK"
    email_message_by_link = "We are glad you have decided to jump on board with this exciting and refreshing month of experimentation and enjoyment! Please {##Click Here##} to verify that this is your email and we can get you started!"
    email_subject_by_link = "Welcome to No Meat May!"
  }
  # Best practice is to use Amazon SES in Production due to daily email limit
  email_configuration {
    reply_to_email_address = "test@gmail.com"
  }
  # SMS requires the use of Amazon SNS

  # Tags
  tags = {
    project = "No Meat May"
  }

  # Devices
  # may remove this as it could be annoying to the user
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }
}


# This part of the AWS tute is here https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-configuring-app-integration.html
resource "aws_cognito_user_pool_client" "no_meat_may" {
  user_pool_id = "${aws_cognito_user_pool.no_meat_may.id}"

  # App clients
  name                   = "no-meat-may-client"
  refresh_token_validity = 30
  # Refers to this - https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-authentication-flow.html?icmpid=docs_cognito_console#amazon-cognito-user-pools-client-side-authentication-flow
  # But is optional, I wonder if it defaults to anything. It doesn't look like it does.
  # I don't have this option applied and the console doesn't tick anything so
  # must be no default
  # explicit_auth_flows =
  # read_attributes  = ["nickname", "custom:motivation"]
  # write_attributes = ["nickname", "custom:motivation"]

  # Triggers
  # Analytics
  # Not sure where these are in Terraform

  # App integration -
  # App client settings - https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-app-idp-settings.html
  # This is the Enabled Identity Providers in teh console
  supported_identity_providers = ["COGNITO"]
  # "${aws_cognito_identity_provider.facebook.provider_name}"
  #  this goes back into the list above
  callback_urls                = ["http://localhost:3000/articles"]
  logout_urls                  = ["http://localhost:3000/articles"]

  # * Don't think I need this b/c I'm not currently using any explicit OAuth identities
  # * Does facebook federated identity count??
  # allowed_oauth_flows                  = ["implicit"]
  # allowed_oauth_scopes                 = ["openid", "email"]
  # allowed_oauth_flows_user_pool_client = true

  # This isn't needed, as it isn't used by the JS SDK.
  # generate_secret = true
}

# * N.B. This is required when using CONFIRM_WITH_LINK b/c it needs a domain name
# * for the page used to confirm a user with the email link
# Domain name
resource "aws_cognito_user_pool_domain" "no_meat_may" {
  user_pool_id = "${aws_cognito_user_pool.no_meat_may.id}"
  # Domain prefix
  domain = "no-meat-may"
}

# Federation -
# Identity providers
# resource "aws_cognito_identity_provider" "facebook" {
#   user_pool_id = "${aws_cognito_user_pool.no_meat_may.id}"

#   provider_name = "Facebook"
#   provider_type = "Facebook"

#   provider_details = {
#     # string is required for this but the example in console suggests a list is applicable
#     authorize_scopes = "email"
#     # TODO the client secret needs to be protected, not sure if the client_id needs to
#     client_id        = ""
#     client_secret    = ""
#   }

#   attribute_mapping = {
#     email      = "email"
#     nickname   = "name"
#     motivation = "location"
#   }
# }

#  !___ COGNITO IDENTITY POOL ___ #
# aws docs for IDENTITY POOLS RESOURCE https://docs.aws.amazon.com/cognito/latest/developerguide/getting-started-with-identity-pools.html
resource "aws_cognito_identity_pool" "no_meat_may_id_pool" {
  identity_pool_name               = "no meat may"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.no_meat_may.id
    provider_name           = aws_cognito_user_pool.no_meat_may.endpoint
    server_side_token_check = false
  }

  supported_login_providers = {
    "graph.facebook.com" = var.fb_provider_id
  }
}

# This is the resource that will determine the authentication of a user through APIG
resource "aws_cognito_identity_pool_roles_attachment" "s3_access_lambda" {
  identity_pool_id = aws_cognito_identity_pool.no_meat_may_id_pool.id

  roles = {
    "authenticated"   = aws_iam_role.api_gateway_access.arn
    "unauthenticated" = aws_iam_role.deny_everything.arn
  }
}

resource "aws_iam_role_policy" "api_gateway_access" {
  name   = "api-gateway-access"
  role   = aws_iam_role.api_gateway_access.id
  policy = data.aws_iam_policy_document.api_gateway_access.json
}

resource "aws_iam_role" "api_gateway_access" {
  name = "ap-gateway-access"
  # This will grant the role the ability for cognito identity to assume it
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.no_meat_may_id_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "api_gateway_access" {
  version = "2012-10-17"
  # ASSUME ROLE
  statement {
    actions = [
      "execute-api:Invoke"
      # "cognito-sync:*",
      # "cognito-identity:*",
      # "mobileanalytics:PutEvents"
    ]

    effect = "Allow"

    resources = ["arn:aws:execute-api:*:*:*"]
  }
}

#  Attaches the deny_everything policy to the deny_everything role
resource "aws_iam_role_policy" "deny_everything" {
  name   = "deny_everything"
  role   = aws_iam_role.deny_everything.id
  policy = data.aws_iam_policy_document.deny_everything.json
}

# for the unauthenticated role in aws_cognito_identity_pool_roles_attachment
resource "aws_iam_role" "deny_everything" {
  name = "deny_everything"
  # This will grant the role the ability for cognito identity to assume it
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.no_meat_may_id_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "deny_everything" {
  version = "2012-10-17"

  statement {
    not_actions = [
      "execute-api:Invoke"
      # "cognito-sync:*",
      # "cognito-identity:*"
    ]

    effect    = "Deny"
    resources = ["*"]
  }
}


#! |--- OUTPUTS ---|  #

#  ___ USER POOL ___ #
output "user_pool_password_policy" {
  value       = aws_cognito_user_pool.no_meat_may.password_policy
  description = "The password policy that we don't want people to know about"
  # this will prevent the output being logged into the console
  sensitive = true
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.no_meat_may.endpoint
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.no_meat_may.arn
}

output "user_pool_id" {
  value = aws_cognito_user_pool.no_meat_may.id
}

# ___ USER POOL CLIENT ___ #
output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.no_meat_may.id
}

# ___ IDENTITY POOL ___ #
output "identity_pool_id" {
  value = aws_cognito_identity_pool.no_meat_may_id_pool.id
}