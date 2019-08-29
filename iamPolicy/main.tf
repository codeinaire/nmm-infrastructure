variable "s3_bucket_name" {}
# variable "identity_pool_arn" {}



# data "aws_iam_policy_document" "assume_role_web_id" {
#   version = "2012-10-17"
#   # ASSUME ROLE
#   statement {
#     actions = [
#       "sts:AssumeRoleWithWebIdentity",
#     ]

#     effect = "Allow"

#     principals {
#       type = "AWS"
#       identifiers = ["${var.identity_pool_arn}"]
#     }
#   }
# }

data "aws_iam_policy_document" "deny_everything" {
  version = "2012-10-17"

  statement {
    not_actions = [
      "s3:List*",
      "s3:Get*"
    ]

    effect = "Deny"
    resources = ["*"]
  }
}

output "lambda_assume_role_policy" {
  value = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

output "lambda_policy_s3_json" {
  value = data.aws_iam_policy_document.s3_list_access_policy.json
}

# output "assume_role_web_id" {
#   value = data.aws_iam_policy_document.assume_role_web_id.json
# }

output "deny_everything" {
  value = data.aws_iam_policy_document.deny_everything.json
}
