variable "allow_admin_create_user_only" {
  type = string
  description = "set to True if only the administrator is allowed to create users"
  default = "false"
}

variable "account_id" {
  default = "711892051847"
}

variable "region" {
  default = ""
}
variable "stage" {
  default = "prod"
}
variable "prefix" {
  default = "seobooker"
}

variable "reply_to" {
  default = "alice.teeters9@gmail.com"
}
