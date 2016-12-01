resource "digitalocean_ssh_key" "flynn" {
  name = "DigitalOcean Terraform Flynn"
  public_key = "${trimspace(file("~/.ssh/flynn.pub"))}"
}

resource "digitalocean_droplet" "flynn-master" {
  image = "ubuntu-16-04-x64"
  name = "flynn-master-2016-11"
  region = "sfo2"
  size = "4gb"
  ssh_keys = ["${digitalocean_ssh_key.flynn.fingerprint}"]

  connection {
    type = "ssh"
    private_key = "${file("~/.ssh/flynn")}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://dl.flynn.io/install-flynn | bash -s -- --version v20161114.0p1",
    ]
  }

  provisioner "file" {
    source = "take-backup"
    destination = "/usr/local/bin/take-backup"
  }

  provisioner "file" {
    source = "restore-backup"
    destination = "/usr/local/bin/restore-backup"
  }

  provisioner "remote-exec" {
    inline = [
      <<EOF
wget -O- --quiet https://github.com/rlmcpherson/s3gof3r/releases/download/v0.5.0/gof3r_0.5.0_linux_amd64.tar.gz |
  tar xz -C /usr/local/bin --strip-components=1 &&
chmod +x /usr/local/bin/gof3r &&
useradd backups -m &&
echo "${aws_iam_access_key.flynn-backups.id}" > ~backups/.s3_access_key_id &&
echo "${aws_iam_access_key.flynn-backups.secret}" > ~backups/.s3_secret_access_key &&
chmod +x /usr/local/bin/take-backup /usr/local/bin/restore-backup
EOF
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "fallocate -l 4G /mnt/swap",
      "mkswap /mnt/swap",
      "chmod 0600 /mnt/swap",
      "swapon /mnt/swap"
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

output "master-ip" {
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
}
