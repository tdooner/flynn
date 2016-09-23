variable "mailgun_api_key" {}
variable "mailgun_smtp_password" {}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

resource "mailgun_domain" "sciolyreg" {
  name = "sciolyreg.org"
  smtp_password = "${var.mailgun_smtp_password}"
}

resource "digitalocean_ssh_key" "flynn" {
  name = "DigitalOcean Terraform Flynn"
  public_key = "${trimspace(file("~/.ssh/flynn.pub"))}"
}

resource "digitalocean_droplet" "flynn-master" {
  image = "ubuntu-14-04-x64"
  name = "flynn-master"
  region = "sfo2"
  size = "2gb"
  ssh_keys = ["${digitalocean_ssh_key.flynn.fingerprint}"]

  connection {
    type = "ssh"
    private_key = "${file("~/.ssh/flynn")}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://dl.flynn.io/install-flynn | bash -s -- --version v20160814.0",
    ]
  }
}

resource "cloudflare_record" "flynn-cluster" {
  domain = "tdooner.com"
  name = "f"
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
  type = "A"
  ttl = 120
}

resource "cloudflare_record" "flynn-cluster-wildcard" {
  domain = "tdooner.com"
  name = "*.f"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 120
}

resource "cloudflare_record" "citymixtape" {
  domain = "citymixtape.com"
  name = "@"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 120
}

resource "cloudflare_record" "sciolyreg" {
  domain = "sciolyreg.org"
  name = "@"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 120
}

resource "cloudflare_record" "sciolyreg-wildcard" {
  domain = "sciolyreg.org"
  name = "*"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 120
}

# this could be wrong in the future if mailgun changes; but for now variables
# are not permitted in count arguments.
resource "cloudflare_record" "sciolyreg-sending-records-0" {
  domain = "sciolyreg.org"
  value = "${mailgun_domain.sciolyreg.sending_records.0.value}"
  name = "${coalesce(replace(mailgun_domain.sciolyreg.sending_records.0.name, "/(.)?sciolyreg.org/", ""), "@")}"
  type = "${mailgun_domain.sciolyreg.sending_records.0.record_type}"
}
resource "cloudflare_record" "sciolyreg-sending-records-1" {
  domain = "sciolyreg.org"
  value = "${mailgun_domain.sciolyreg.sending_records.1.value}"
  name = "${coalesce(replace(mailgun_domain.sciolyreg.sending_records.1.name, ".sciolyreg.org", ""), "@")}"
  type = "${mailgun_domain.sciolyreg.sending_records.1.record_type}"
}

output "master-ip" {
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
}
