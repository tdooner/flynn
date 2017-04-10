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
# with the new server. Follow these rough instructions:
#
# 1) provision a new flynn server by uncommenting the below module
# 2) manually copy a backup from the old server to the new server's S3
# bucket and sync over the blobstore:
#   backup=backup-2017-04-09-21-10-50.tar.gz
#   aws s3 cp s3://flynn-backups-tdooner/$backup s3://testing-flynn-backups-tdooner/$backup
#   aws s3 sync s3://flynn-blobstore-tdooner s3://testing-flynn-blobstore-tdooner
# 3) restore the backup on the new server with the "restore-backup" script
# 4) migrate the new cluster to the correct CLUSTER_DOMAIN
#   Add the following entries to your /etc/hosts:
#     ip=138.68.249.132
#     cat <<EOF | sudo tee -a /etc/hosts
#     $ip status.f.tdooner.com
#     $ip controller.f.tdooner.com
#     $ip dashboard.f.tdooner.com
#     $ip f.tdooner.com
#     EOF
#   verify that a command like `flynn -a blobstore ps` works and returns a task
#   on the testing cluster.
#   then run:
#     flynn cluster migrate-domain f2.tdooner.com
# 5) update the blobstore to not be pulling from the old cluster:
#   bucket=$(terraform output -module flynn-master-testing blobstore_bucket)
#   access_key_id=$(terraform output -module flynn-master-testing blobstore_access_key_id)
#   secret_access_key=$(terraform output -module flynn-master-testing blobstore_secret_access_key)
#   if [ -n "$bucket" -a -n "$access_key_id" -a -n "$secret_access_key" ]; then
#     flynn -a blobstore env set BACKEND_S3MAIN="backend=s3 region=us-west-2 \
#       bucket=$bucket access_key_id=$access_key_id secret_access_key=$secret_access_key"
#   else
#     echo "ERROR: Argument is missing :("
#   fi
#
# When adding new resources, either set a variable which results in "count = 0"
# for the production instance, or create the resource in this file and pass in
# the necessary attributes as variables to the module. Then do something weird
# like "${compact(list("${var.some_attribute_here}"))}" for the value of a
# list.
#
# module "flynn-master-testing" {
#   source = "./modules/flynn-server"
#   ssh_fingerprint = "${digitalocean_ssh_key.flynn.fingerprint}"
#
#   flynn_version = "v20170321.0"
#   cluster_subdomain = "f2"
#   cluster_name_prefix = "testing-"
#
#   volume_id = "${digitalocean_volume.flynn-data.id}"
# }

module "apps" {
  source = "./modules/apps"

  mailgun_smtp_password = "${var.mailgun_smtp_password}"
}
