resource "cloudflare_record" "citymixtape" {
  domain = "citymixtape.com"
  name = "@"
  value = "f.tdooner.com"
  type = "CNAME"
  ttl = 120
}

resource "statuscake_test" "citymixtape" {
  website_name = "citymixtape.com"
  website_url = "${cloudflare_record.citymixtape.domain}"
  test_type = "HTTP"
}
