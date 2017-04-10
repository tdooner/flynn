variable "mailgun_api_key" {}
variable "mailgun_smtp_password" {}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias = "east"
  region = "us-east-1"
}

resource "digitalocean_ssh_key" "flynn" {
  name = "DigitalOcean Terraform Flynn"
  public_key = "${trimspace(file("~/.ssh/flynn.pub"))}"
}

module "flynn-master" {
  source = "./modules/flynn-server"
  ssh_fingerprint = "${digitalocean_ssh_key.flynn.fingerprint}"
}

# To upgrade flynn to a new release, uncomment this locally and test everything
# with the new server. Then, make a backup and transfer everything to the new
# cluster.
#
# When adding new resources, either set a variable which results in "count = 0"
# for the production instance, or create the resource in this file and pass in
# the necessary attributes as variables to the module. Then do something weird
# like "${compact(list("${var.some_attribute_here}"))}" for the value of a
# list.
module "flynn-master-testing" {
  source = "./modules/flynn-server"
  ssh_fingerprint = "${digitalocean_ssh_key.flynn.fingerprint}"

  flynn_version = "v20170321.0"
  cluster_subdomain = "f2"
  cluster_name_prefix = "testing-"

  volume_id = "${digitalocean_volume.flynn-data.id}"
}

module "apps" {
  source = "./modules/apps"

  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
