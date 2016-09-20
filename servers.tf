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
      "curl -fsSL https://dl.flynn.io/install-flynn -- --version v20160814.0 | bash",
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

output "master-ip" {
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
}
