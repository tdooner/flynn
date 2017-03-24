variable "mailgun_api_key" {}
variable "mailgun_smtp_password" {}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

provider "aws" {
  region = "us-west-2"
}

module "flynn-master" {
  source = "./modules/flynn-server"
}

module "apps" {
  source = "./modules/apps"

  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
