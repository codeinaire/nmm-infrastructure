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
# output "identity_pool_id" {
#   value = module.cognito.identity_pool_id
# }

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