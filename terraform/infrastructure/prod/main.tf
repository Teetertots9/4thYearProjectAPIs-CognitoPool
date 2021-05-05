#
# Configure the S3 backend, which needs to be set up separately
#
terraform {
  backend "s3" {
    region     = "eu-west-1"
    bucket         = "seobooker.tf-prod-infra-state"
    key            = "cognito/terraform.tfstate"
    dynamodb_table = "seobooker_prod_infra"
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = var.region
}

resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.prefix}-user-pool-${var.stage}"

  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only
  }

  username_attributes = [
    "email"
  ]

  password_policy {
    minimum_length = 10
    require_lowercase = false
    require_uppercase = false
    require_symbols = false
    require_numbers = false
  }
  auto_verified_attributes = ["email"]

  
  email_configuration {
    source_arn = "arn:aws:ses:${var.region}:${var.account_id}:identity/${var.reply_to}"
    reply_to_email_address = "${var.reply_to}"
    email_sending_account = "DEVELOPER"
  }
  
}

resource "aws_cognito_user_pool_client" "pool_client" {
  name = "${var.prefix}-client-pool-${var.stage}"
  generate_secret = false       # There is a limitation in 'Amplify' that means we can't set this to TRUE
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]  # Enable sign-in API for server-based authentication (ADMIN_NO_SRP_AUTH)

  user_pool_id = aws_cognito_user_pool.user_pool.id

  depends_on = [aws_cognito_user_pool.user_pool]
}

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Managed by Terraform"
}
