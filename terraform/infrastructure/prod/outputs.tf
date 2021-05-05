output "aws_cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "aws_cognito_client_id" {
  value = aws_cognito_user_pool_client.pool_client.id
}
