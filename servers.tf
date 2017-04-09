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

module "flynn-master" {
  source = "./modules/flynn-server"
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

  flynn_version = "v20170321.0"
  cluster_subdomain = "f2"
  cluster_name_prefix = "testing-"

  volume_id = "${digitalocean_volume.flynn-data.id}"
}

module "apps" {
  source = "./modules/apps"

  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}

resource "digitalocean_volume" "flynn-data" {
  // region = "${var.region}"
  region = "sfo2"
  // name = "${var.cluster_name_prefix}flynn-data"
  name = "testing-flynn-data"
  size = 100
  // description = "Data for the ${var.cluster_name_prefix}flynn cluster"
  description = "Data for the testing-flynn cluster"
}
