resource "digitalocean_volume" "flynn-data" {
  region = "${var.region}"
  name = "${var.cluster_name_prefix}flynn-data"
  size = 100
  description = "Data for the ${var.cluster_name_prefix}flynn cluster"
}

resource "digitalocean_droplet" "flynn-master" {
  image = "ubuntu-16-04-x64"
  name = "${var.cluster_name_prefix}flynn-master-2017-04"
  region = "${var.region}"
  size = "4gb"
  ssh_keys = ["${var.ssh_fingerprint}"]
  volume_ids = ["${digitalocean_volume.flynn-data.id}"]

  connection {
    type = "ssh"
    private_key = "${file("~/.ssh/flynn")}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://dl.flynn.io/install-flynn | bash -s -- --version ${var.flynn_version} --zpool-create-device /dev/sda --zpool-create-options '-f'",
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
echo "${aws_s3_bucket.flynn-backups.bucket}" > ~backups/.s3_bucket_name &&
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
  name = "${var.cluster_subdomain}"
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
  type = "A"
  ttl = 120
}

resource "cloudflare_record" "flynn-cluster-wildcard" {
  domain = "tdooner.com"
  name = "*.${var.cluster_subdomain}"
  value = "${var.cluster_subdomain}.tdooner.com"
  type = "CNAME"
  ttl = 120
}

output "master-ip" {
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
}
