#
# Configure the S3 backend, which needs to be set up separately
#
terraform {
  backend "s3" {
    region     = "eu-west-1"
    bucket         = "seobooker.tf-dev-infra-state"
    key            = "cognito/terraform.tfstate"
    dynamodb_table = "seobooker_dev_infra"
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
    minimum_length = 8
    require_lowercase = true
    require_uppercase = true
    require_symbols = false
    require_numbers = true
  }
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "preferred_username"
    required                 = true
    string_attribute_constraints {
      min_length = 1
      max_length = 32
    }
  }
  
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

resource "aws_cognito_user_pool_client" "native_pool_client" {
  name = "${var.prefix}-native-client-pool-${var.stage}"
  generate_secret = true       
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]  

  user_pool_id = aws_cognito_user_pool.user_pool.id

  depends_on = [aws_cognito_user_pool.user_pool]
}

resource "aws_iam_role" "artist_role" {
  name = "artist-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
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

resource "aws_iam_role" "venue_role" {
  name = "venue-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
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

resource "aws_iam_role" "fan_role" {
  name = "fan-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
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

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Managed by Terraform"
}

resource "aws_cognito_user_group" "artist" {
  name         = "artist"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Managed by Terraform"
  precedence   = 42
  role_arn     = aws_iam_role.artist_role.arn
}

resource "aws_cognito_user_group" "venue" {
  name         = "venue"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Managed by Terraform"
  precedence   = 42
  role_arn     = aws_iam_role.venue_role.arn
}
resource "aws_cognito_user_group" "fan" {
  name         = "fan"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  description  = "Managed by Terraform"
  precedence   = 42
  role_arn     = aws_iam_role.fan_role.arn
}

resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${var.prefix} identity pool ${var.stage}"
  allow_unauthenticated_identities = true

  cognito_identity_providers {
    client_id               = "${aws_cognito_user_pool_client.pool_client.id}"
    provider_name           = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
    server_side_token_check = false
  }

}

resource "aws_iam_role" "identity-pool-role" {
  name = "${var.prefix}_identity_pool_role-${var.stage}"

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
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "identity-pool-policy" {
  name = "${var.prefix}-identity-pool-policy-${var.stage}"
  role = "${aws_iam_role.identity-pool-role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutBucketAcl",
                "s3:GetObject",
                "s3:GetObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::${var.prefix}-images-dev/*",
                "arn:aws:s3:::${var.prefix}-images-dev"
            ]
        }
    ]
}
EOF
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = "${aws_cognito_identity_pool.identity_pool.id}"

  role_mapping {
    identity_provider         = "cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}:${aws_cognito_user_pool_client.pool_client.id}"
    ambiguous_role_resolution = "AuthenticatedRole"
    type                      = "Token"
  }

  roles = {
    "authenticated"   = "${aws_iam_role.identity-pool-role.arn}"
    "unauthenticated" = "${aws_iam_role.identity-pool-role.arn}"
  }
}
