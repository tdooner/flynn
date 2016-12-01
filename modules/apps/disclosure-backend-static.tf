resource "cloudflare_record" "disclosure-backend-static" {
  domain = "tdooner.com"
  name = "disclosure-backend-static"
  value = "f.tdooner.com"
  type = "CNAME"
  proxied = true
}

resource "statuscake_test" "disclosure-backend" {
  website_name = "disclosure-backend-static.tdooner.com"
  website_url = "disclosure-backend-static.tdooner.com"
  test_type = "HTTP"
}
