variable "allow_admin_create_user_only" {
  type = string
  description = "set to True if only the administrator is allowed to create users"
  default = "false"
}

variable "account_id" {
  default = "703387863451"
}

variable "region" {
  default = "eu-west-1"
}
variable "stage" {
  default = "dev"
}
variable "prefix" {
  default = "seobooker"
}

variable "reply_to" {
  default = "alice.teeters9@gmail.com"
}
