variable "mailgun_api_key" {}
variable "mailgun_smtp_password" {}
variable "statuscake_api_key" {}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

provider "aws" {
  region = "us-west-2"
}

provider "statuscake" {
  username = "tomdooner"
  apikey = "${var.statuscake_api_key}"
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

resource "aws_iam_policy" "flynn-backups" {
  name = "flynn-backups"
  path = "/"
  description = "User to upload flynn backups"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1480272378109",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.flynn-backups.bucket}/*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "flynn-backups" {
  name = "flynn-backups"
  path = "/"
}

resource "aws_iam_policy_attachment" "flynn-backups" {
  name = "flynn-backups"
  users = ["${aws_iam_user.flynn-backups.name}"]
  policy_arn = "${aws_iam_policy.flynn-backups.arn}"
}

resource "aws_iam_access_key" "flynn-backups" {
  user = "${aws_iam_user.flynn-backups.name}"
}

resource "aws_s3_bucket" "flynn-backups" {
  bucket = "flynn-backups-tdooner"
  acl = "private"
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

resource "cloudflare_record" "disclosure-backend-static" {
  domain = "tdooner.com"
  name = "disclosure-backend-static"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 120
  proxied = true
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

# status checks for services
resource "statuscake_test" "sciolyreg" {
  website_name = "sciolyreg.org"
  website_url = "${cloudflare_record.sciolyreg.domain}"
  test_type = "HTTP"
}

resource "statuscake_test" "citymixtape" {
  website_name = "citymixtape.com"
  website_url = "${cloudflare_record.citymixtape.domain}"
  test_type = "HTTP"
}

resource "statuscake_test" "disclosure-backend" {
  website_name = "disclosure-backend-static.tdooner.com"
  website_url = "disclosure-backend-static.tdooner.com"
  test_type = "HTTP"
}

output "master-ip" {
  value = "${digitalocean_droplet.flynn-master.ipv4_address}"
}
