variable "mailgun_smtp_password" {}

resource "mailgun_domain" "sciolyreg" {
  name = "sciolyreg.org"
  smtp_password = "${var.mailgun_smtp_password}"
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

resource "statuscake_test" "sciolyreg" {
  website_name = "sciolyreg.org"
  website_url = "${cloudflare_record.sciolyreg.domain}"
  test_type = "HTTP"
}

