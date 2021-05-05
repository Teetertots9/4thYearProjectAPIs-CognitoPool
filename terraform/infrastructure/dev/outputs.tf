output "aws_cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "aws_cognito_client_id" {
  value = aws_cognito_user_pool_client.pool_client.id
}

output "aws_cognito_native_client_id" {
  value = aws_cognito_user_pool_client.native_pool_client.id
}


output "aws_cognito_identity_pool" {
  value = aws_cognito_identity_pool.identity_pool.id
}

output "aws_cognito_identity_pool_arn" {
  value = aws_cognito_identity_pool.identity_pool.arn
}