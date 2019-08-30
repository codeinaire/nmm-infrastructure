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
# output "identity_pool_id" {
#   value = aws_cognito_identity_pool.no_meat_may_id_pool.id
# }